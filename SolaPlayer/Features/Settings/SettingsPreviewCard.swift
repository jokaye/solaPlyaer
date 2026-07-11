import SwiftUI

struct SettingsPreviewCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let palette: AppPalette

    var body: some View {
        palette.gradient
            .frame(height: 190)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1:08")
                        .font(.system(size: 48, weight: .ultraLight))
                    Text("城市清晨 · 环境采集")
                        .font(.headline)
                    Text(palette.label)
                        .font(.caption)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.18), in: .capsule)
                }
                .foregroundStyle(.white)
                .padding(AppSpacing.controls)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
            }
            .clipShape(.rect(cornerRadius: AppRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(.white.opacity(0.34), lineWidth: 1)
            }
            .shadow(color: palette.colors.top.opacity(0.2), radius: 18, y: 10)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.9), value: palette)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("当前主题预览，\(palette.label)")
    }
}
