import Foundation
import Testing
@testable import SolaPlayer

struct WaveformServiceTests {
    @Test("真实 PCM 可分桶归一化并生成稳定缓存")
    func extractsAndCachesWaveform() async throws {
        let fixture = try makeFixture()
        defer { removeFixture(fixture.root) }
        let service = try WaveformService(cacheDirectory: fixture.cacheDirectory)

        let firstSamples = try await service.samples(
            for: fixture.audioURL,
            bucketCount: 24
        )

        #expect(firstSamples.count == 24)
        #expect(firstSamples.allSatisfy { $0.isFinite && (0.14...1).contains($0) })
        let maximum = try #require(firstSamples.max())
        #expect(maximum == 1)

        let cacheFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.cacheDirectory,
            includingPropertiesForKeys: nil
        )
        let cacheURL = try #require(cacheFiles.first)
        #expect(cacheFiles.count == 1)
        let cacheDataBeforeSecondLoad = try Data(contentsOf: cacheURL)

        let secondSamples = try await service.samples(
            for: fixture.audioURL,
            bucketCount: 24
        )
        let cacheDataAfterSecondLoad = try Data(contentsOf: cacheURL)

        #expect(secondSamples == firstSamples)
        #expect(cacheDataAfterSecondLoad == cacheDataBeforeSecondLoad)
    }

    @Test("损坏的派生缓存会删除并从原音频重建")
    func rebuildsCorruptCache() async throws {
        let fixture = try makeFixture()
        defer { removeFixture(fixture.root) }
        let service = try WaveformService(cacheDirectory: fixture.cacheDirectory)
        let expectedSamples = try await service.samples(
            for: fixture.audioURL,
            bucketCount: 12
        )
        let cacheFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.cacheDirectory,
            includingPropertiesForKeys: nil
        )
        let cacheURL = try #require(cacheFiles.first)
        try Data("corrupt cache".utf8).write(to: cacheURL, options: .atomic)

        let rebuiltSamples = try await service.samples(
            for: fixture.audioURL,
            bucketCount: 12
        )
        let rebuiltData = try Data(contentsOf: cacheURL)
        let decodedCache = try PropertyListDecoder().decode([Float].self, from: rebuiltData)

        #expect(rebuiltSamples == expectedSamples)
        #expect(decodedCache == expectedSamples)
    }

    private func makeFixture() throws -> (
        root: URL,
        audioURL: URL,
        cacheDirectory: URL
    ) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let audioURL = root.appendingPathComponent("fixture.wav")
        let cacheDirectory = root.appendingPathComponent("Waveforms", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try makePCMFile(at: audioURL)
        return (root, audioURL, cacheDirectory)
    }

    private func makePCMFile(at url: URL) throws {
        let sampleRate: UInt32 = 8_000
        let channelCount: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let frameCount = Int(sampleRate)
        let bytesPerSample = Int(bitsPerSample / 8)
        let dataByteCount = frameCount * Int(channelCount) * bytesPerSample

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        appendLittleEndian(UInt32(36 + dataByteCount), to: &data)
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(channelCount, to: &data)
        appendLittleEndian(sampleRate, to: &data)
        let byteRate = sampleRate * UInt32(channelCount) * UInt32(bytesPerSample)
        appendLittleEndian(byteRate, to: &data)
        appendLittleEndian(channelCount * UInt16(bytesPerSample), to: &data)
        appendLittleEndian(bitsPerSample, to: &data)
        data.append(contentsOf: "data".utf8)
        appendLittleEndian(UInt32(dataByteCount), to: &data)

        for frame in 0..<frameCount {
            let envelope = frame < frameCount / 2 ? 0.25 : 0.85
            let phase = 2 * Double.pi * 440 * Double(frame) / Double(sampleRate)
            let sample = Int16((sin(phase) * envelope * Double(Int16.max)).rounded())
            appendLittleEndian(sample, to: &data)
        }

        try data.write(to: url, options: .atomic)
    }

    private func appendLittleEndian<Value: FixedWidthInteger>(
        _ value: Value,
        to data: inout Data
    ) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            data.append(contentsOf: bytes)
        }
    }

    private func removeFixture(_ root: URL) {
        do {
            try FileManager.default.removeItem(at: root)
        } catch {
            Issue.record("无法清理波形测试目录：\(error.localizedDescription)")
        }
    }
}
