#if DEBUG
import Foundation

@MainActor
final class DesignPreviewAudioEngine: AudioPlaying {
    private(set) var currentTime: TimeInterval = 68
    private(set) var duration: TimeInterval = 228
    private(set) var isPlaying = false

    func load(url: URL) throws {
        currentTime = 68
        duration = 228
        isPlaying = false
    }

    func play() throws {
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func seek(to time: TimeInterval) {
        currentTime = min(max(time, 0), duration)
    }

    func stop() {
        currentTime = 0
        isPlaying = false
    }

    func consumeSessionError() -> Error? {
        nil
    }
}
#endif
