import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.globalPalette) private var globalPaletteKey = AppPalette.clearSky.rawValue

    private var selectedPalette: AppPalette {
        AppPalette(rawValue: globalPaletteKey) ?? .clearSky
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.standard) {
                SettingsPreviewCard(palette: selectedPalette)

                Text("选择全局天气主题")
                    .font(.headline)
                    .foregroundStyle(AppColor.ink)
                    .padding(.top, AppSpacing.small)

                Text("未单独设置主题的音频会使用这里的配色。")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.secondaryInk)

                ForEach(AppPalette.allCases) { palette in
                    PaletteSelectionRow(
                        palette: palette,
                        isSelected: palette == selectedPalette,
                        action: { select(palette) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.controls)
            .padding(.vertical, AppSpacing.standard)
        }
        .background(LibraryBackground())
        .navigationTitle("主题配色")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.ink)
    }

    private func select(_ palette: AppPalette) {
        withAnimation(.easeInOut(duration: 0.35)) {
            globalPaletteKey = palette.rawValue
        }
    }
}
