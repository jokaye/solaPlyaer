import SwiftUI

struct ScopeChipButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let accentColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected == false, let accentColor {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(selectedFill)
        .foregroundStyle(selectedForeground)
        .shadow(color: isSelected ? AppColor.ink.opacity(0.16) : .clear, radius: 8, y: 5)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectedFill: Color {
        if isSelected {
            return colorScheme == .dark ? .white : AppColor.ink
        }
        return colorScheme == .dark ? .white.opacity(0.1) : AppColor.ink.opacity(0.06)
    }

    private var selectedForeground: Color {
        if isSelected {
            return colorScheme == .dark ? .black : .white
        }
        return .primary
    }
}
