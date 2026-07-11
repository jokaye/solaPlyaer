import SwiftUI

struct ImportCardView: View {
    let isEmpty: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(AppColor.secondaryInk.opacity(0.38), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .allowsHitTesting(false)
        }
        .accessibilityHint("打开系统文件选择器")
    }
}
