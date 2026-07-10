import Foundation

struct MembershipRemoval: Identifiable, Equatable {
    let id: UUID
    let itemID: UUID
    let groupID: UUID
    let orderInGroup: Int
    let itemTitle: String

    init(
        id: UUID = UUID(),
        itemID: UUID,
        groupID: UUID,
        orderInGroup: Int,
        itemTitle: String
    ) {
        self.id = id
        self.itemID = itemID
        self.groupID = groupID
        self.orderInGroup = orderInGroup
        self.itemTitle = itemTitle
    }
}
