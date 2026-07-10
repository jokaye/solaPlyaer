import SwiftUI
import SwiftData

@main
struct SolaPlayerApp: App {
    private let modelContainer: ModelContainer
    @State private var libraryStore: LibraryStore

    init() {
        do {
            let modelContainer = try AppModelContainer.make()
            let persistence = PersistenceService(modelContext: modelContainer.mainContext)
            let importer = try ImportService()

            self.modelContainer = modelContainer
            _libraryStore = State(
                initialValue: try LibraryStore(
                    persistence: persistence,
                    importer: importer
                )
            )
        } catch {
            fatalError("Unable to initialize Sola Player: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: libraryStore)
                .modelContainer(modelContainer)
        }
    }
}
