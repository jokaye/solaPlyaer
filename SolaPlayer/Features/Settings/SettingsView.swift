import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.globalPalette) private var globalPaletteKey = AppPalette.clearSky.rawValue

    var body: some View {
        Form {
            Section("播放页主题") {
                ForEach(AppPalette.allCases) { palette in
                    Button(action: { select(palette) }) {
                        HStack(spacing: AppSpacing.standard) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(palette.gradient)
                                .frame(width: 52, height: 32)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.primary.opacity(0.08))
                                }
                                .accessibilityHidden(true)

                            Text(palette.label)
                                .foregroundStyle(.primary)

                            Spacer()

                            if globalPaletteKey == palette.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColor.ink)
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityValue(
                        globalPaletteKey == palette.rawValue ? "已选择" : "未选择"
                    )
                }
            } footer: {
                Text("全局主题用于所有未设置单曲主题的音频。单曲主题可在音库的曲目菜单中覆盖。")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(_ palette: AppPalette) {
        globalPaletteKey = palette.rawValue
    }
}
