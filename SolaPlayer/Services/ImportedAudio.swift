import Foundation

struct ImportedAudio: Sendable {
    let title: String
    let bookmark: Data
    let localCopyURL: URL
    let duration: TimeInterval
}
