import SwiftUI

struct RootView: View {
    let store: LibraryStore
    let playerStore: PlayerStore
    let markerStore: MarkerStore

    @State private var path: [RootRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LibraryView(store: store, onPlay: play)
                .navigationDestination(for: RootRoute.self) { route in
                    switch route {
                    case .about:
                        AboutView()
                    case .settings:
                        SettingsView()
                    case let .player(scope, itemID):
                        PlayerView(
                            store: playerStore,
                            libraryStore: store,
                            markerStore: markerStore,
                            queue: store.items(in: scope).map(PlaybackQueueItem.init),
                            initialItemID: itemID,
                            sourceName: store.name(for: scope)
                        )
                    }
                }
        }
    }

    private func play(_ item: AudioItem, in scope: PlaybackScope) {
        path.append(.player(scope: scope, itemID: item.id))
    }
}
