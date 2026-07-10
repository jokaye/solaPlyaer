import Foundation
@testable import SolaPlayer

@MainActor
final class StubAudioEngine: AudioPlaying {
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 100
    private(set) var isPlaying = false
    private(set) var loadedURLs: [URL] = []
    private(set) var stopCount = 0
    var failingLoadURLs: Set<URL> = []
    var nextPlayError: Error?

    func load(url: URL) throws {
        if failingLoadURLs.contains(url) {
            throw TestFailure.loadFailed
        }
        loadedURLs.append(url)
        currentTime = 0
        duration = 100
        isPlaying = false
    }

    func play() throws {
        if let nextPlayError {
            self.nextPlayError = nil
            throw nextPlayError
        }
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func seek(to time: TimeInterval) {
        currentTime = min(max(time, 0), duration)
    }

    func stop() {
        stopCount += 1
        currentTime = 0
        isPlaying = false
    }

    func consumeSessionError() -> Error? {
        nil
    }
}
