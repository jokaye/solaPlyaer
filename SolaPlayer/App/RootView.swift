import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
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
                .tint(AppPalette.clearSky.colors.top)
                .foregroundStyle(.white)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AppSpacing.content)
            .foregroundStyle(.primary)
            .navigationTitle("音库")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RootView()
}
