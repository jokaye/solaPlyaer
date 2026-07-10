import SwiftUI
import SwiftData

@main
struct SolaPlayerApp: App {
    private let modelContainer: ModelContainer?
    private let initializationFailureMessage: String?
    private let initialRoute: RootRoute?
    @State private var libraryStore: LibraryStore?
    @State private var playerStore: PlayerStore?
    @State private var markerStore: MarkerStore?

    init() {
        let dependencies = Self.makeDependencies()
        modelContainer = dependencies.modelContainer
        initializationFailureMessage = dependencies.failureMessage
        initialRoute = dependencies.initialRoute
        _libraryStore = State(initialValue: dependencies.libraryStore)
        _playerStore = State(initialValue: dependencies.playerStore)
        _markerStore = State(initialValue: dependencies.markerStore)
    }

    private static func makeDependencies() -> (
        modelContainer: ModelContainer?,
        failureMessage: String?,
        libraryStore: LibraryStore?,
        playerStore: PlayerStore?,
        markerStore: MarkerStore?,
        initialRoute: RootRoute?
    ) {
        do {
            #if DEBUG
            let previewRoute = ProcessInfo.processInfo.environment["SOLA_DESIGN_PREVIEW"]
            #else
            let previewRoute: String? = nil
            #endif

            let modelContainer = try AppModelContainer.make(inMemory: previewRoute != nil)
            #if DEBUG
            if previewRoute != nil {
                try DesignPreviewSeeder.seed(modelContext: modelContainer.mainContext)
            }
            #endif
            let persistence = PersistenceService(modelContext: modelContainer.mainContext)
            let importer = try ImportService()
            let engine: any AudioPlaying
            let waveformService: any WaveformProviding
            #if DEBUG
            if previewRoute != nil {
                engine = DesignPreviewAudioEngine()
                waveformService = DesignPreviewWaveformService()
            } else {
                engine = AudioEngine()
                waveformService = try WaveformService()
            }
            #else
            engine = AudioEngine()
            waveformService = try WaveformService()
            #endif

            let libraryStore = try LibraryStore(
                persistence: persistence,
                importer: importer
            )
            let playerStore = PlayerStore(
                engine: engine,
                waveformService: waveformService
            )
            let markerStore = MarkerStore(persistence: persistence)
            libraryStore.setItemDeletionHandler { [weak playerStore, weak markerStore] itemID in
                playerStore?.removeDeletedItem(id: itemID)
                markerStore?.handleDeletedAudio(id: itemID)
            }

            if previewRoute == "library", let itemID = libraryStore.items.first?.id {
                try playerStore.start(
                    queue: libraryStore.items.map(PlaybackQueueItem.init),
                    initialItemID: itemID,
                    sourceName: "默认列表"
                )
            }

            let initialRoute: RootRoute?
            if previewRoute == "player", let itemID = libraryStore.items.first?.id {
                initialRoute = .player(scope: .master, itemID: itemID)
            } else {
                initialRoute = nil
            }

            return (modelContainer, nil, libraryStore, playerStore, markerStore, initialRoute)
        } catch {
            return (nil, error.localizedDescription, nil, nil, nil, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer,
               let libraryStore,
               let playerStore,
               let markerStore {
                RootView(
                    store: libraryStore,
                    playerStore: playerStore,
                    markerStore: markerStore,
                    initialRoute: initialRoute
                )
                .modelContainer(modelContainer)
            } else {
                AppInitializationFailureView(
                    message: initializationFailureMessage ?? "未知初始化错误"
                )
            }
        }
    }
}
