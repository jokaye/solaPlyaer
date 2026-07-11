import SwiftUI

struct LibraryBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.12, blue: 0.16), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.73, green: 0.85, blue: 1), location: 0),
                    .init(color: Color(red: 0.90, green: 0.95, blue: 1), location: 0.34),
                    .init(color: Color(red: 0.95, green: 0.98, blue: 0.97), location: 0.60),
                    .init(color: .white, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
