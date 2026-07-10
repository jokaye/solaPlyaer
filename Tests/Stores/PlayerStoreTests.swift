import Foundation
import Testing
@testable import SolaPlayer

struct PlayerStoreTests {
    @MainActor
    @Test("删除当前曲目会继续播放快照中的下一首")
    func deletingCurrentItemAdvancesQueue() throws {
        let items = makeItems(count: 3)
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )
        let queue = items.map(PlaybackQueueItem.init)

        try store.start(
            queue: queue,
            initialItemID: items[1].id,
            sourceName: "测试分组"
        )
        store.removeDeletedItem(id: items[1].id)

        #expect(store.queue.map(\.id) == [items[0].id, items[2].id])
        #expect(store.currentItem?.id == items[2].id)
        #expect(store.isPlaying)
    }

    @MainActor
    @Test("删除当前曲后下一首加载失败会停止并清空播放会话")
    func deletingCurrentItemStopsWhenNextLoadFails() throws {
        let items = makeItems(count: 3)
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )
        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[1].id,
            sourceName: "测试分组"
        )
        engine.failingLoadURLs = [try #require(items[2].localCopyURL)]

        store.removeDeletedItem(id: items[1].id)

        #expect(store.queue.isEmpty)
        #expect(store.currentItem == nil)
        #expect(store.isPlaying == false)
        #expect(engine.stopCount == 1)
    }

    @MainActor
    @Test("可从固定队列中选择另一首并立即播放")
    func selectingQueueItemLoadsAndPlaysIt() throws {
        let items = makeItems(count: 3)
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )

        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[0].id,
            sourceName: "通勤"
        )
        try store.playItem(id: items[2].id)

        #expect(store.currentItem?.id == items[2].id)
        #expect(store.isPlaying)
        #expect(engine.loadedURLs.last == items[2].localCopyURL)
    }

    @MainActor
    @Test("选择队列外曲目会明确失败且不改变当前项")
    func selectingUnknownQueueItemFails() throws {
        let items = makeItems(count: 2)
        let store = PlayerStore(
            engine: StubAudioEngine(),
            waveformService: StubWaveformService()
        )
        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[0].id,
            sourceName: "默认列表"
        )

        do {
            try store.playItem(id: UUID())
            Issue.record("预期队列外曲目被拒绝。")
        } catch PlayerStoreError.itemNotFound {
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        #expect(store.currentItem?.id == items[0].id)
    }

    @MainActor
    @Test("下一首加载失败时保留原曲和播放状态")
    func failedNextItemLoadPreservesCurrentPlayback() throws {
        let items = makeItems(count: 2)
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )
        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[0].id,
            sourceName: "默认列表"
        )
        engine.failingLoadURLs = [try #require(items[1].localCopyURL)]

        #expect(throws: TestFailure.loadFailed) {
            try store.playNext()
        }

        #expect(store.currentItem?.id == items[0].id)
        #expect(store.isPlaying)
        #expect(engine.loadedURLs.last == items[0].localCopyURL)
    }

    @MainActor
    @Test("下一首播放失败时恢复原曲和播放状态")
    func failedNextItemPlaybackRestoresCurrentPlayback() throws {
        let items = makeItems(count: 2)
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )
        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[0].id,
            sourceName: "默认列表"
        )
        engine.nextPlayError = TestFailure.playFailed

        #expect(throws: TestFailure.playFailed) {
            try store.playNext()
        }

        #expect(store.currentItem?.id == items[0].id)
        #expect(store.isPlaying)
        #expect(engine.loadedURLs.last == items[0].localCopyURL)
    }

    @MainActor
    @Test("删除快照末尾的当前曲目会回到首项")
    func deletingLastCurrentItemWrapsToStart() throws {
        let items = makeItems(count: 3)
        let store = PlayerStore(
            engine: StubAudioEngine(),
            waveformService: StubWaveformService()
        )

        try store.start(
            queue: items.map(PlaybackQueueItem.init),
            initialItemID: items[2].id,
            sourceName: "默认列表"
        )
        store.removeDeletedItem(id: items[2].id)

        #expect(store.currentItem?.id == items[0].id)
    }

    @MainActor
    @Test("删除队列最后一项会停止并清空播放状态")
    func deletingOnlyItemStopsPlayback() throws {
        let item = makeItems(count: 1)[0]
        let engine = StubAudioEngine()
        let store = PlayerStore(
            engine: engine,
            waveformService: StubWaveformService()
        )

        try store.start(
            queue: [PlaybackQueueItem(item)],
            initialItemID: item.id,
            sourceName: "默认列表"
        )
        store.removeDeletedItem(id: item.id)

        #expect(store.queue.isEmpty)
        #expect(store.currentItem == nil)
        #expect(store.duration == 0)
        #expect(engine.stopCount == 1)
    }

    @MainActor
    private func makeItems(count: Int) -> [AudioItem] {
        (0..<count).map { index in
            AudioItem(
                title: "曲目 \(index)",
                bookmark: Data(),
                localCopyURL: URL(fileURLWithPath: "/tmp/track-\(index).m4a"),
                duration: 100,
                masterOrder: index
            )
        }
    }
}
