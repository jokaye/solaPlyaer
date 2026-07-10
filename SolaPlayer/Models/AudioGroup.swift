import Foundation
import SwiftData

@Model
final class AudioGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorKey: String?
    var chipOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Membership.group)
    var memberships: [Membership] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorKey: String? = nil,
        chipOrder: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.chipOrder = chipOrder
        self.createdAt = createdAt
    }
}
