import Foundation

@MainActor
protocol AudioPlaying: AnyObject {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }

    func load(url: URL) throws
    func play() throws
    func pause()
    func seek(to time: TimeInterval)
    func stop()
    func consumeSessionError() -> Error?
}
