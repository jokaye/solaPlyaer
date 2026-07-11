import SwiftUI

struct PlayerGlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(.white.opacity(AppMaterial.controlFillOpacity), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(.white.opacity(AppMaterial.controlStrokeOpacity), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.68 : 1)
            .scaleEffect(configuration.isPressed && reduceMotion == false ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
