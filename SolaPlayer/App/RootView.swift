import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.clearSky.gradient
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.large) {
                    Image(systemName: "waveform")
                        .font(.system(size: 52, weight: .ultraLight))
                        .accessibilityHidden(true)

                    VStack(spacing: AppSpacing.small) {
                        Text("Sola Player")
                            .appFont(AppTypography.libraryTitle)

                        Text("让声音像天气一样流动")
                            .appFont(AppTypography.secondary)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink("关于与诊断") {
                        AboutView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(AppMaterial.controlFillOpacity))
                    .foregroundStyle(AppColor.ink)
                    .controlSize(.large)
                }
                .padding(AppSpacing.content)
            }
            .foregroundStyle(AppColor.ink)
            .navigationTitle("音库")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RootView()
}
