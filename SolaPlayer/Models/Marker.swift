import Foundation
import SwiftData

@Model
final class Marker {
    @Attribute(.unique) var id: UUID
    var time: TimeInterval
    var title: String
    var note: String
    var createdAt: Date
    var owner: AudioItem

    init(
        id: UUID = UUID(),
        time: TimeInterval,
        title: String,
        note: String = "",
        createdAt: Date = .now,
        owner: AudioItem
    ) {
        self.id = id
        self.time = time
        self.title = title
        self.note = note
        self.createdAt = createdAt
        self.owner = owner
    }
}
