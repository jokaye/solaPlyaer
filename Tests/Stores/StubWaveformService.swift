import Foundation
@testable import SolaPlayer

struct StubWaveformService: WaveformProviding {
    func samples(for audioURL: URL, bucketCount: Int) async throws -> [Float] {
        Array(repeating: 0.5, count: bucketCount)
    }
}
