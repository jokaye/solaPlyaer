import SwiftUI

struct TrackRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: AudioItem
    let membershipCount: Int
    let isCurrent: Bool
    let canRemoveFromCurrentGroup: Bool
    let selectedPalette: AppPalette?
    let onPlay: () -> Void
    let onChooseGroups: () -> Void
    let onSetPalette: (AppPalette?) -> Void
    let onRemoveFromCurrentGroup: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    (selectedPalette ?? .clearSky).gradient
                        .frame(width: 52, height: 52)
                        .clipShape(.rect(cornerRadius: AppRadius.thumbnail))
                        .overlay {
                            MiniWaveformView(seed: item.id)
                                .padding(8)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .appFont(AppTypography.libraryTrackTitle)
                            .foregroundStyle(AppColor.ink)
                            .lineLimit(1)

                        Text("所属 \(membershipCount) 个分组 · \(item.duration.durationText)")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.secondaryInk)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("进入播放页")

            Menu("曲目操作", systemImage: "ellipsis") {
                Button("加入分组…", systemImage: "folder.badge.plus", action: onChooseGroups)

                Menu("播放主题", systemImage: "paintpalette") {
                    Button(
                        "跟随全局",
                        systemImage: selectedPalette == nil ? "checkmark" : "circle",
                        action: { onSetPalette(nil) }
                    )

                    ForEach(AppPalette.allCases) { palette in
                        Button(
                            palette.label,
                            systemImage: selectedPalette?.rawValue == palette.rawValue
                                ? "checkmark"
                                : "circle",
                            action: { onSetPalette(palette) }
                        )
                    }
                }

                if canRemoveFromCurrentGroup {
                    Button(
                        "移出当前分组",
                        systemImage: "minus.circle",
                        role: .destructive,
                        action: onRemoveFromCurrentGroup
                    )
                }

                Button("重命名", systemImage: "pencil", action: onRename)
                Button("彻底删除", systemImage: "trash", role: .destructive, action: onDelete)
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(minHeight: 70)
        .background(cardColor, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isCurrent ? AppPalette.mint.colors.top : Color.primary.opacity(0.05),
                    lineWidth: isCurrent ? 1.5 : 1
                )
                .allowsHitTesting(false)
        }
        .shadow(
            color: isCurrent
                ? AppPalette.mint.colors.top.opacity(0.16)
                : .black.opacity(colorScheme == .dark ? 0.16 : 0.055),
            radius: isCurrent ? 16 : 10,
            y: 4
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canRemoveFromCurrentGroup {
                Button(
                    "移出",
                    systemImage: "minus.circle",
                    role: .destructive,
                    action: onRemoveFromCurrentGroup
                )
            }
        }
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white.opacity(0.94)
    }
}
