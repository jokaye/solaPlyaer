import SwiftUI

struct RootView: View {
    let store: LibraryStore

    var body: some View {
        NavigationStack {
            LibraryView(store: store)
                .navigationDestination(for: RootRoute.self) { route in
                    switch route {
                    case .about:
                        AboutView()
                    }
                }
        }
    }
}
