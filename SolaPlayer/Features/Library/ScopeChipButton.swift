import SwiftUI

struct ScopeChipButton: View {
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
        .tint(isSelected ? AppColor.ink : AppColor.ink.opacity(0.06))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .shadow(color: isSelected ? AppColor.ink.opacity(0.16) : .clear, radius: 8, y: 5)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
