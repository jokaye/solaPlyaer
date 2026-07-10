import SwiftUI

struct ScrubberPillView: View {
    let text: String

    var body: some View {
        VStack(spacing: -2) {
            Text(text)
                .appFont(AppTypography.pill)
                .foregroundStyle(AppColor.ink)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(.white, in: .capsule)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            Rectangle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .rotationEffect(.degrees(45))
        }
        .accessibilityHidden(true)
    }
}
