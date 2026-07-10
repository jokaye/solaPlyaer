import Foundation
import SwiftData

@Model
final class Marker {
    @Attribute(.unique) var id: UUID
    var ownerID: UUID
    var time: TimeInterval
    var title: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        ownerID: UUID,
        time: TimeInterval,
        title: String,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.time = time
        self.title = title
        self.note = note
        self.createdAt = createdAt
    }
}
