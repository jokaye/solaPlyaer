import Foundation
import SwiftData

@Model
final class Membership {
    @Attribute(.unique) var id: UUID
    var group: AudioGroup
    var item: AudioItem
    var orderInGroup: Int
    var addedAt: Date

    init(
        id: UUID = UUID(),
        group: AudioGroup,
        item: AudioItem,
        orderInGroup: Int,
        addedAt: Date = .now
    ) {
        self.id = id
        self.group = group
        self.item = item
        self.orderInGroup = orderInGroup
        self.addedAt = addedAt
    }
}
