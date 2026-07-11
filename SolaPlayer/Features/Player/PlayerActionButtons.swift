import SwiftUI

struct PlayerActionButtons: View {
    let membershipCount: Int
    let canGroup: Bool
    let canMark: Bool
    let onGroup: () -> Void
    let onMark: () -> Void

    var body: some View {
        HStack {
            Button(action: onGroup) {
                HStack(spacing: 7) {
                    Image(systemName: "rectangle.3.group")
                    Text("分组")
                    Text("\(membershipCount)")
                        .appFont(AppTypography.pill)
                        .foregroundStyle(AppColor.ink)
                        .frame(width: 24, height: 24)
                        .background(.white, in: .circle)
                }
            }
            .disabled(canGroup == false)

            Spacer()

            Button(action: onMark) {
                Label("标记此刻", systemImage: "bookmark")
            }
            .disabled(canMark == false)
        }
        .font(.subheadline)
        .buttonStyle(PlayerGlassButtonStyle())
        .frame(minHeight: 44)
    }
}
