import Foundation
import Testing
@testable import SolaPlayer

struct LibraryStoreTests {
    @MainActor
    @Test("导入只进入默认列表")
    func importAddsOnlyToMasterList() async throws {
        let context = try LibraryTestContext(titles: ["晨间播客"])

        try await context.store.importFiles(context.sourceURLs)

        let item = try #require(context.store.items.first)
        #expect(context.store.items.count == 1)
        #expect(context.store.visibleItems.map(\.id) == [item.id])
        #expect(item.memberships.isEmpty)
        #expect(item.masterOrder == 0)
    }

    @MainActor
    @Test("音频可多归属，移出和撤销不影响默认列表")
    func membershipsAreIndependentFromMasterList() async throws {
        let context = try LibraryTestContext(titles: ["访谈"])
        try await context.store.importFiles(context.sourceURLs)
        let item = try #require(context.store.items.first)
        let focus = try context.store.createGroup(name: "专注")
        let commute = try context.store.createGroup(name: "通勤")

        try context.store.add(item, to: [focus, commute])
        #expect(context.store.membershipCount(for: item) == 2)

        try context.store.remove(item, from: focus)
        #expect(context.store.items(in: .master).map(\.id) == [item.id])
        #expect(context.store.items(in: .group(focus.id)).isEmpty)
        #expect(context.store.items(in: .group(commute.id)).map(\.id) == [item.id])

        try context.store.undoPendingRemoval()
        #expect(context.store.items(in: .group(focus.id)).map(\.id) == [item.id])
    }

    @MainActor
    @Test("删除分组不删除音频")
    func deletingGroupKeepsAudioItem() async throws {
        let context = try LibraryTestContext(titles: ["课程"])
        try await context.store.importFiles(context.sourceURLs)
        let item = try #require(context.store.items.first)
        let group = try context.store.createGroup(name: "稍后听")
        try context.store.add(item, to: [group])

        try context.store.deleteGroup(group)

        #expect(context.store.groups.isEmpty)
        #expect(context.store.items(in: .master).map(\.id) == [item.id])
    }

    @MainActor
    @Test("组内排序不改变默认列表顺序")
    func groupOrderingIsIndependent() async throws {
        let context = try LibraryTestContext(titles: ["一", "二", "三"])
        try await context.store.importFiles(context.sourceURLs)
        let masterOrder = context.store.items(in: .master).map(\.id)
        let group = try context.store.createGroup(name: "自定义顺序")
        try context.store.add(context.store.items, to: [group])
        try context.store.setScope(.group(group.id))

        try context.store.reorderItems(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        let expectedGroupOrder = Array(masterOrder.dropFirst()) + [masterOrder[0]]
        #expect(context.store.visibleItems.map(\.id) == expectedGroupOrder)
        #expect(context.store.items(in: .master).map(\.id) == masterOrder)
    }

    @MainActor
    @Test("批量加入和移出分组不改变默认列表")
    func bulkMembershipChangesKeepMasterList() async throws {
        let context = try LibraryTestContext(titles: ["甲", "乙", "丙"])
        try await context.store.importFiles(context.sourceURLs)
        let masterIDs = context.store.items(in: .master).map(\.id)
        let group = try context.store.createGroup(name: "批量整理")

        try context.store.add(context.store.items, to: [group])
        #expect(context.store.items(in: .group(group.id)).count == 3)

        try context.store.remove(Array(context.store.items.prefix(2)), from: group)
        #expect(context.store.items(in: .group(group.id)).count == 1)
        #expect(context.store.items(in: .master).map(\.id) == masterIDs)
    }

    @MainActor
    @Test("分组顺序和颜色可持久更新")
    func groupMetadataCanBeUpdated() throws {
        let context = try LibraryTestContext(titles: [])
        let first = try context.store.createGroup(name: "第一组")
        _ = try context.store.createGroup(name: "第二组")
        _ = try context.store.createGroup(name: "第三组")

        try context.store.setColor(AppPalette.lake.rawValue, for: first)
        try context.store.reorderGroups(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        #expect(context.store.groups.map(\.name) == ["第二组", "第三组", "第一组"])
        #expect(context.store.groups.last?.colorKey == AppPalette.lake.rawValue)
    }
}
