import Foundation
import SwiftData
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
    @Test("分组顺序和颜色可更新")
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

    @MainActor
    @Test("磁盘容器重建后仍能读取音频和分组")
    func persistenceSurvivesContainerRecreation() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Issue.record("无法清理测试目录：\(error.localizedDescription)")
            }
        }

        let storeURL = directory.appendingPathComponent("SolaPlayer.store")
        let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
        let imported = ImportedAudio(
            title: "持久化测试",
            bookmark: Data([1]),
            localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            duration: 90
        )

        do {
            let container = try AppModelContainer.make(storeURL: storeURL)
            let persistence = PersistenceService(modelContext: container.mainContext)
            let store = try LibraryStore(
                persistence: persistence,
                importer: StubAudioImporter(imports: [sourceURL: imported])
            )
            try await store.importFiles([sourceURL])
            _ = try store.createGroup(name: "跨启动分组", adding: store.items)
        }

        do {
            let container = try AppModelContainer.make(storeURL: storeURL)
            let persistence = PersistenceService(modelContext: container.mainContext)
            let store = try LibraryStore(
                persistence: persistence,
                importer: StubAudioImporter(imports: [:])
            )
            let group = try #require(store.groups.first)

            #expect(store.items.map(\.title) == ["持久化测试"])
            #expect(store.groups.map(\.name) == ["跨启动分组"])
            #expect(store.items(in: .group(group.id)).map(\.title) == ["持久化测试"])
        }
    }

    @MainActor
    @Test("新建并加入在保存失败时整体回滚")
    func createGroupAndAddRollsBackTogether() async throws {
        let container = try AppModelContainer.make(inMemory: true)
        let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
        let imported = ImportedAudio(
            title: "事务测试",
            bookmark: Data([1]),
            localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            duration: 30
        )
        let base = PersistenceService(modelContext: container.mainContext)
        let persistence = FailingPersistence(base: base)
        let store = try LibraryStore(
            persistence: persistence,
            importer: StubAudioImporter(imports: [sourceURL: imported])
        )
        try await store.importFiles([sourceURL])
        let item = try #require(store.items.first)
        persistence.failNextSave = true

        do {
            _ = try store.createGroup(name: "不应残留", adding: [item])
            Issue.record("预期保存失败。")
        } catch TestFailure.saveFailed {
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        #expect(store.groups.isEmpty)
        #expect(store.membershipCount(for: item) == 0)
    }

    @MainActor
    @Test("删除保存失败时恢复暂存文件和数据")
    func failedDeleteRestoresStagedFileAndItem() async throws {
        let container = try AppModelContainer.make(inMemory: true)
        let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
        let imported = ImportedAudio(
            title: "删除补偿测试",
            bookmark: Data([1]),
            localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            duration: 45
        )
        let base = PersistenceService(modelContext: container.mainContext)
        let persistence = FailingPersistence(base: base)
        let importer = DeletionTrackingImporter(imports: [sourceURL: imported])
        let store = try LibraryStore(persistence: persistence, importer: importer)
        try await store.importFiles([sourceURL])
        let item = try #require(store.items.first)
        persistence.failNextSave = true

        do {
            try await store.deleteItem(item)
            Issue.record("预期保存失败。")
        } catch TestFailure.saveFailed {
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        let restoreCount = await importer.restoreCount
        let finalizeCount = await importer.finalizeCount
        #expect(store.items.map(\.id) == [item.id])
        #expect(restoreCount == 1)
        #expect(finalizeCount == 0)
    }

    @MainActor
    @Test("最终文件清理失败会报错并可在之后重试清理")
    func cleanupFailureRemainsRetryable() async throws {
        let container = try AppModelContainer.make(inMemory: true)
        let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
        let imported = ImportedAudio(
            title: "清理重试测试",
            bookmark: Data([1]),
            localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            duration: 50
        )
        let persistence = PersistenceService(modelContext: container.mainContext)
        let importer = DeletionTrackingImporter(
            imports: [sourceURL: imported],
            failFinalization: true
        )
        let store = try LibraryStore(persistence: persistence, importer: importer)
        try await store.importFiles([sourceURL])
        let item = try #require(store.items.first)

        do {
            try await store.deleteItem(item)
            Issue.record("预期最终文件清理失败。")
        } catch let error as LibraryStoreError {
            guard case .fileCleanupFailed = error else {
                Issue.record("收到 LibraryStoreError，但不是文件清理失败。")
                return
            }
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        #expect(store.items.isEmpty)
        try await store.reconcilePendingFileDeletions()
        let reconcileCount = await importer.reconcileCount
        #expect(reconcileCount == 1)
    }
}
