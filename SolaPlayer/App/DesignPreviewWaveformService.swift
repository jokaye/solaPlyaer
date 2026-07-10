#if DEBUG
import Foundation

struct DesignPreviewWaveformService: WaveformProviding {
    func samples(for audioURL: URL, bucketCount: Int) async throws -> [Float] {
        (0..<bucketCount).map { index in
            let envelope = sin(Double(index) / Double(max(bucketCount - 1, 1)) * .pi)
            let detail = abs(sin(Double(index) * 0.91) * cos(Double(index) * 0.37))
            return Float(max(0.14, min(1, envelope * (0.35 + detail * 0.65))))
        }
    }
}
#endif
