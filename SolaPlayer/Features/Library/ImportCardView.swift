import SwiftUI

struct ImportCardView: View {
    let isEmpty: Bool
    let isImporting: Bool
    let onAudioImport: () -> Void
    let onFolderImport: () -> Void

    var body: some View {
        Menu {
            Button("选择音频文件", systemImage: "waveform.badge.plus", action: onAudioImport)
            Button("选择音频文件夹", systemImage: "folder.badge.plus", action: onFolderImport)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEmpty ? "导入第一段音频" : "导入音频")
                        .font(.headline)
                    Text("文件 · 文件夹 · 链接 · AirDrop")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColor.ink, in: .rect(cornerRadius: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .disabled(isImporting)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(AppColor.secondaryInk.opacity(0.38), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .allowsHitTesting(false)
        }
        .accessibilityHint("选择导入音频文件或文件夹")
    }
}
