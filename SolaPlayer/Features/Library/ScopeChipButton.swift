import SwiftUI

struct ScopeChipButton: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                } else if let accentColor {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(isSelected ? AppColor.ink : Color.secondary.opacity(0.12))
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
