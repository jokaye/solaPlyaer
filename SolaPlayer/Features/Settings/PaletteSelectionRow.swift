import SwiftUI

struct PaletteSelectionRow: View {
    let palette: AppPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.standard) {
                palette.gradient
                    .frame(width: 64, height: 42)
                    .clipShape(.rect(cornerRadius: 13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(.white.opacity(0.5), lineWidth: 1)
                    }

                Text(palette.label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColor.ink)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.colors.top : AppColor.secondaryInk.opacity(0.35))
            }
            .padding(.horizontal, AppSpacing.standard)
            .frame(minHeight: 66)
            .background(.white.opacity(0.88), in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? palette.colors.top.opacity(0.72) : .white.opacity(0.5), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "已选择" : "未选择")
    }
}
