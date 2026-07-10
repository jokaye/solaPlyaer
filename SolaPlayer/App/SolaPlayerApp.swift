import SwiftUI
import SwiftData

@main
struct SolaPlayerApp: App {
    private let modelContainer: ModelContainer?
    private let initializationFailureMessage: String?
    @State private var libraryStore: LibraryStore?
    @State private var playerStore: PlayerStore?
    @State private var markerStore: MarkerStore?

    init() {
        let dependencies = Self.makeDependencies()
        modelContainer = dependencies.modelContainer
        initializationFailureMessage = dependencies.failureMessage
        _libraryStore = State(initialValue: dependencies.libraryStore)
        _playerStore = State(initialValue: dependencies.playerStore)
        _markerStore = State(initialValue: dependencies.markerStore)
    }

    private static func makeDependencies() -> (
        modelContainer: ModelContainer?,
        failureMessage: String?,
        libraryStore: LibraryStore?,
        playerStore: PlayerStore?,
        markerStore: MarkerStore?
    ) {
        do {
            let modelContainer = try AppModelContainer.make()
            let persistence = PersistenceService(modelContext: modelContainer.mainContext)
            let importer = try ImportService()
            let waveformService = try WaveformService()

            let libraryStore = try LibraryStore(
                persistence: persistence,
                importer: importer
            )
            let playerStore = PlayerStore(
                engine: AudioEngine(),
                waveformService: waveformService
            )
            let markerStore = MarkerStore(persistence: persistence)
            libraryStore.setItemDeletionHandler { [weak playerStore, weak markerStore] itemID in
                playerStore?.removeDeletedItem(id: itemID)
                markerStore?.handleDeletedAudio(id: itemID)
            }

            return (modelContainer, nil, libraryStore, playerStore, markerStore)
        } catch {
            return (nil, error.localizedDescription, nil, nil, nil)
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
                    markerStore: markerStore
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
