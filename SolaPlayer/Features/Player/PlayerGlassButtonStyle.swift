import SwiftUI

struct PlayerGlassButtonStyle: ButtonStyle {
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
