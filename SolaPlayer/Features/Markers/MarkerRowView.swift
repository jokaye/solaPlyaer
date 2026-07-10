import SwiftUI

struct MarkerRowView: View {
    let marker: Marker

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.standard) {
            Text(marker.time.durationText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(marker.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if marker.note.isEmpty == false {
                    Text(marker.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, 14)
        .background(.white.opacity(0.9), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .contentShape(.rect)
    }
}
