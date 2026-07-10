import SwiftUI

struct TrackRowView: View {
    let item: AudioItem
    let membershipCount: Int
    let canRemoveFromCurrentGroup: Bool
    let onChooseGroups: () -> Void
    let onRemoveFromCurrentGroup: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.standard) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(AppColor.ink)
                .frame(width: 52, height: 52)
                .background(AppPalette.clearSky.gradient, in: .rect(cornerRadius: AppRadius.thumbnail))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .appFont(AppTypography.libraryTrackTitle)
                    .lineLimit(1)

                Text("\(membershipCount) 个分组 · \(item.duration.durationText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.small)

            Menu("音频操作", systemImage: "ellipsis") {
                Button("加入分组…", systemImage: "folder.badge.plus", action: onChooseGroups)

                if canRemoveFromCurrentGroup {
                    Button("移出当前分组", systemImage: "minus.circle", role: .destructive, action: onRemoveFromCurrentGroup)
                }

                Button("重命名", systemImage: "pencil", action: onRename)
                Button("彻底删除", systemImage: "trash", role: .destructive, action: onDelete)
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
        }
        .frame(minHeight: 56)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canRemoveFromCurrentGroup {
                Button("移出", systemImage: "minus.circle", role: .destructive, action: onRemoveFromCurrentGroup)
            }
        }
    }
}
