import Foundation
import SwiftData
import Testing
@testable import SolaPlayer

struct MarkerStoreTests {
    @MainActor
    @Test("标记可新增、编辑备注、跳转排序和删除")
    func markerLifecycle() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let persistence = PersistenceService(modelContext: container.mainContext)
        let item = AudioItem(
            title: "标记测试",
            bookmark: Data(),
            localCopyURL: nil,
            duration: 120,
            masterOrder: 0
        )
        persistence.insert(item)
        try persistence.save()

        let store = MarkerStore(persistence: persistence)
        try store.load(for: item.id)
        let later = try store.addMarker(for: item.id, at: 80, duration: item.duration)
        let earlier = try store.addMarker(for: item.id, at: 20, duration: item.duration)

        #expect(store.markers.map(\.id) == [earlier.id, later.id])

        try store.update(earlier, title: "关键观点", note: "回听这一段")
        #expect(store.markers.first?.title == "关键观点")
        #expect(store.markers.first?.note == "回听这一段")

        try store.delete(later)
        #expect(store.markers.map(\.id) == [earlier.id])
    }

    @MainActor
    @Test("删除音频会在同一持久化事务中删除全部标记")
    func deletingAudioCascadesMarkers() async throws {
        let container = try AppModelContainer.make(inMemory: true)
        let persistence = PersistenceService(modelContext: container.mainContext)
        let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
        let imported = ImportedAudio(
            title: "级联测试",
            bookmark: Data([1]),
            localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
            duration: 60
        )
        let libraryStore = try LibraryStore(
            persistence: persistence,
            importer: StubAudioImporter(imports: [sourceURL: imported])
        )
        try await libraryStore.importFiles([sourceURL])
        let item = try #require(libraryStore.items.first)
        let markerStore = MarkerStore(persistence: persistence)
        _ = try markerStore.addMarker(for: item.id, at: 12, duration: item.duration)

        try await libraryStore.deleteItem(item)
        try markerStore.load(for: item.id)

        #expect(markerStore.markers.isEmpty)
    }
}
