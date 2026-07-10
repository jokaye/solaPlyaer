import SwiftUI

struct ImportCardView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("导入第一段音频")
                        .font(.headline)
                    Text("文件或文件夹 · AirDrop")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColor.ink, in: .rect(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.standard)
        }
        .buttonStyle(.plain)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .allowsHitTesting(false)
        }
        .accessibilityHint("打开系统文件选择器")
    }
}
