import Foundation
import SwiftData

@Model
final class AudioItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var bookmark: Data
    var localCopyURL: URL?
    var duration: TimeInterval
    var createdAt: Date
    var masterOrder: Int
    var waveformCacheURL: URL?
    var paletteKey: String?

    @Relationship(deleteRule: .cascade, inverse: \Membership.item)
    var memberships: [Membership] = []

    init(
        id: UUID = UUID(),
        title: String,
        bookmark: Data,
        localCopyURL: URL?,
        duration: TimeInterval,
        createdAt: Date = .now,
        masterOrder: Int,
        waveformCacheURL: URL? = nil,
        paletteKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.bookmark = bookmark
        self.localCopyURL = localCopyURL
        self.duration = duration
        self.createdAt = createdAt
        self.masterOrder = masterOrder
        self.waveformCacheURL = waveformCacheURL
        self.paletteKey = paletteKey
    }
}
