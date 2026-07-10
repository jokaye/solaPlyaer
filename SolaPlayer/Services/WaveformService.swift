import AudioToolbox
import AVFoundation
import CoreMedia
import CryptoKit
import Foundation

actor WaveformService: WaveformProviding {
    private static let cacheVersion = 1
    private static let readChunkSize = 1_048_576

    private let fileManager: FileManager
    private let cacheDirectory: URL

    init(cacheDirectory: URL? = nil) throws {
        let fileManager = FileManager()
        self.fileManager = fileManager

        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            guard let cachesDirectory = fileManager.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            ).first else {
                throw CocoaError(.fileNoSuchFile)
            }
            self.cacheDirectory = cachesDirectory
                .appendingPathComponent("Waveforms", isDirectory: true)
        }
    }

    func samples(for audioURL: URL, bucketCount: Int) async throws -> [Float] {
        guard bucketCount > 0 else {
            throw WaveformServiceError.invalidBucketCount
        }
        guard fileManager.fileExists(atPath: audioURL.path) else {
            throw WaveformServiceError.fileNotFound(audioURL.path)
        }

        let contentHash = try hashContents(of: audioURL)
        let cacheURL = cacheFileURL(hash: contentHash, bucketCount: bucketCount)
        if let cached = try cachedSamples(at: cacheURL, bucketCount: bucketCount) {
            return cached
        }

        let extracted = try await extractSamples(
            from: audioURL,
            bucketCount: bucketCount
        )
        try Task.checkCancellation()
        try writeCache(extracted, to: cacheURL)
        return extracted
    }

    private func extractSamples(from audioURL: URL, bucketCount: Int) async throws -> [Float] {
        let asset = AVURLAsset(url: audioURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw WaveformServiceError.noAudioTrack
        }

        let duration = try await asset.load(.duration)
        let formatDescriptions = try await track.load(.formatDescriptions)
        guard duration.seconds.isFinite,
              duration.seconds > 0,
              let formatDescription = formatDescriptions.first,
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(
                  formatDescription
              )?.pointee,
              streamDescription.mSampleRate > 0,
              streamDescription.mChannelsPerFrame > 0 else {
            throw WaveformServiceError.invalidAudioFormat
        }

        let channelCount = Int(streamDescription.mChannelsPerFrame)
        let totalFrameCount = max(
            Int(duration.seconds * streamDescription.mSampleRate),
            1
        )
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
        )
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            throw WaveformServiceError.readerConfigurationFailed
        }
        reader.add(output)
        guard reader.startReading() else {
            throw WaveformServiceError.readerStartFailed(
                reader.error?.localizedDescription ?? "未知错误"
            )
        }

        var squareSums = Array(repeating: 0.0, count: bucketCount)
        var peaks = Array(repeating: 0.0, count: bucketCount)
        var sampleCounts = Array(repeating: 0, count: bucketCount)
        var processedFrameCount = 0

        do {
            while let sampleBuffer = output.copyNextSampleBuffer() {
                try Task.checkCancellation()
                guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                    throw WaveformServiceError.sampleReadFailed("采样缓冲区为空")
                }

                let byteCount = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(count: byteCount)
                let copyStatus = data.withUnsafeMutableBytes { bytes in
                    guard let destination = bytes.baseAddress else {
                        return OSStatus(kCMBlockBufferBadPointerParameterErr)
                    }
                    return CMBlockBufferCopyDataBytes(
                        blockBuffer,
                        atOffset: 0,
                        dataLength: byteCount,
                        destination: destination
                    )
                }
                guard copyStatus == noErr else {
                    throw WaveformServiceError.sampleReadFailed(
                        "复制 PCM 缓冲区失败（\(copyStatus)）"
                    )
                }

                let frameCount = try accumulate(
                    data: data,
                    channelCount: channelCount,
                    startingFrame: processedFrameCount,
                    totalFrameCount: totalFrameCount,
                    squareSums: &squareSums,
                    peaks: &peaks,
                    sampleCounts: &sampleCounts
                )
                processedFrameCount += frameCount
            }
        } catch {
            reader.cancelReading()
            throw error
        }

        switch reader.status {
        case .completed:
            return normalizedSamples(
                squareSums: squareSums,
                peaks: peaks,
                sampleCounts: sampleCounts
            )
        case .cancelled:
            throw CancellationError()
        case .failed:
            throw WaveformServiceError.sampleReadFailed(
                reader.error?.localizedDescription ?? "未知错误"
            )
        default:
            throw WaveformServiceError.sampleReadFailed("读取器状态异常")
        }
    }

    private func accumulate(
        data: Data,
        channelCount: Int,
        startingFrame: Int,
        totalFrameCount: Int,
        squareSums: inout [Double],
        peaks: inout [Double],
        sampleCounts: inout [Int]
    ) throws -> Int {
        try data.withUnsafeBytes { rawBuffer in
            let pcmSamples = rawBuffer.bindMemory(to: Int16.self)
            let frameCount = pcmSamples.count / channelCount

            for frameOffset in 0..<frameCount {
                if frameOffset.isMultiple(of: 4_096) {
                    try Task.checkCancellation()
                }

                var magnitude = 0.0
                let firstSampleIndex = frameOffset * channelCount
                for channel in 0..<channelCount {
                    let sample = Int32(pcmSamples[firstSampleIndex + channel])
                    magnitude += abs(Double(sample)) / 32_768.0
                }
                magnitude /= Double(channelCount)

                let absoluteFrame = startingFrame + frameOffset
                let normalizedPosition = Double(absoluteFrame) / Double(totalFrameCount)
                let bucketIndex = min(
                    Int(normalizedPosition * Double(squareSums.count)),
                    squareSums.count - 1
                )
                squareSums[bucketIndex] += magnitude * magnitude
                peaks[bucketIndex] = max(peaks[bucketIndex], magnitude)
                sampleCounts[bucketIndex] += 1
            }
            return frameCount
        }
    }

    private func normalizedSamples(
        squareSums: [Double],
        peaks: [Double],
        sampleCounts: [Int]
    ) -> [Float] {
        let rawSamples = squareSums.indices.map { index in
            guard sampleCounts[index] > 0 else {
                return 0.0
            }
            let rms = sqrt(squareSums[index] / Double(sampleCounts[index]))
            return rms * 0.65 + peaks[index] * 0.35
        }
        let maximum = rawSamples.max() ?? 0
        guard maximum > 0 else {
            return Array(repeating: 0.14, count: squareSums.count)
        }
        return rawSamples.map { sample in
            Float(min(max(sample / maximum, 0.14), 1))
        }
    }

    private func hashContents(of url: URL) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer {
            try? fileHandle.close()
        }

        var hasher = SHA256()
        while true {
            try Task.checkCancellation()
            let data = try fileHandle.read(upToCount: Self.readChunkSize) ?? Data()
            guard data.isEmpty == false else {
                break
            }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func cacheFileURL(hash: String, bucketCount: Int) -> URL {
        cacheDirectory.appendingPathComponent(
            "v\(Self.cacheVersion)-\(hash)-\(bucketCount).waff",
            isDirectory: false
        )
    }

    private func cachedSamples(at url: URL, bucketCount: Int) throws -> [Float]? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let samples = try PropertyListDecoder().decode([Float].self, from: data)
            guard samples.count == bucketCount,
                  samples.allSatisfy({ $0.isFinite && (0.14...1).contains($0) }) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return samples
        } catch let cacheError {
            do {
                try fileManager.removeItem(at: url)
                return nil
            } catch let removalError {
                throw WaveformServiceError.cacheRecoveryFailed(
                    path: url.path,
                    reason: "\(cacheError.localizedDescription); \(removalError.localizedDescription)"
                )
            }
        }
    }

    private func writeCache(_ samples: [Float], to url: URL) throws {
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        let data = try PropertyListEncoder().encode(samples)
        try data.write(to: url, options: .atomic)
    }
}
