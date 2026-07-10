import SwiftUI

struct MarkerRowView: View {
    let marker: Marker

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.standard) {
            Text(marker.time.durationText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(AppColor.ink)

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
        .contentShape(.rect)
    }
}
