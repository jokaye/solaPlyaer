import SwiftUI

struct AppInitializationFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("无法启动 Sola Player", systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: AppSpacing.standard) {
                Text("应用数据或系统音频服务初始化失败。请关闭并重新打开应用；如果问题持续，请保留以下诊断信息。")

                Text(message)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(AppSpacing.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.secondary.opacity(0.08), in: .rect(cornerRadius: AppRadius.card))
            }
        }
        .padding(AppSpacing.content)
    }
}
