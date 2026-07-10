import SwiftUI

struct AppFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat

    private let weight: Font.Weight
    private let tracking: CGFloat

    init(token: AppFontToken) {
        _size = ScaledMetric(wrappedValue: token.size, relativeTo: token.relativeTo)
        weight = token.weight
        tracking = token.tracking
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .tracking(tracking)
    }
}

extension View {
    func appFont(_ token: AppFontToken) -> some View {
        modifier(AppFontModifier(token: token))
    }
}
