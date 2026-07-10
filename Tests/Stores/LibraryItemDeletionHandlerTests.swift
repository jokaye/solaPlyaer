import Foundation
import Testing
@testable import SolaPlayer

struct LibraryItemDeletionHandlerTests {
    @MainActor
    @Test("删除提交成功后通知播放队列")
    func successfulDeletionNotifiesHandler() async throws {
        let context = try LibraryTestContext(titles: ["待删除"])
        try await context.store.importFiles(context.sourceURLs)
        let item = try #require(context.store.items.first)
        let expectedItemID = item.id
        var notifiedItemID: UUID?
        context.store.setItemDeletionHandler { itemID in
            notifiedItemID = itemID
        }

        try await context.store.deleteItem(item)

        #expect(notifiedItemID == expectedItemID)
    }
}
