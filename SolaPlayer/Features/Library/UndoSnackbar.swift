import SwiftUI

struct UndoSnackbar: View {
    let removal: MembershipRemoval
    let undo: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.standard) {
            Text("已将“\(removal.itemTitle)”移出分组")
                .font(.subheadline)
                .lineLimit(2)

            Spacer(minLength: AppSpacing.small)

            Button("撤销", action: undo)
                .bold()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .background(AppColor.ink, in: .rect(cornerRadius: AppRadius.glassBar))
        .shadow(color: .black.opacity(0.16), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
    }
}
