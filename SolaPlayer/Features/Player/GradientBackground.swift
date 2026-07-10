import SwiftUI

struct GradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let palette: AppPalette

    var body: some View {
        palette.gradient
            .ignoresSafeArea()
            .animation(
                .easeInOut(duration: reduceMotion ? 0 : 0.9),
                value: palette
            )
    }
}
