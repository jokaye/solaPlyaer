import Foundation

struct PlaybackQueueItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let localCopyURL: URL?
    let duration: TimeInterval
    let paletteKey: String?

    init(_ item: AudioItem) {
        id = item.id
        title = item.title
        localCopyURL = item.localCopyURL
        duration = item.duration
        paletteKey = item.paletteKey
    }
}
