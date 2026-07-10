import Foundation

struct StagedAudioDeletion: Sendable {
    let originalURL: URL
    let stagedURL: URL
    let directoryURL: URL
}
