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
        do {
            let modelContainer = try AppModelContainer.make()
            let persistence = PersistenceService(modelContext: modelContainer.mainContext)
            let importer = try ImportService()
            let waveformService = try WaveformService()

            self.modelContainer = modelContainer
            initializationFailureMessage = nil
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

            _libraryStore = State(initialValue: libraryStore)
            _playerStore = State(initialValue: playerStore)
            _markerStore = State(initialValue: markerStore)
        } catch {
            modelContainer = nil
            initializationFailureMessage = error.localizedDescription
            _libraryStore = State(initialValue: nil)
            _playerStore = State(initialValue: nil)
            _markerStore = State(initialValue: nil)
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
