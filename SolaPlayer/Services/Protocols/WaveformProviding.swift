import Foundation

protocol WaveformProviding: Sendable {
    func samples(for audioURL: URL, bucketCount: Int) async throws -> [Float]
}
