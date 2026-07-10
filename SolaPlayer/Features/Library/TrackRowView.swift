import SwiftUI

struct TrackRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.editMode) private var editMode

    @State private var isConfirmingRemoval = false

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
            if isEditing, canRemoveFromCurrentGroup {
                Button("准备移出分组", systemImage: "minus", action: toggleRemovalConfirmation)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(red: 1, green: 0.37, blue: 0.48), in: .circle)
                    .shadow(color: Color.red.opacity(0.28), radius: 5, y: 2)
            }

            Button(action: handlePlay) {
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

            if isEditing, canRemoveFromCurrentGroup {
                if isConfirmingRemoval {
                    Button("移出", systemImage: "minus.circle", action: confirmRemoval)
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Color(red: 1, green: 0.37, blue: 0.48))
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, height: 44)
                        .accessibilityLabel("拖动调整顺序")
                }
            } else {
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
        }
        .animation(.easeInOut(duration: 0.22), value: isConfirmingRemoval)
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
        .onChange(of: isEditing) { _, editing in
            if editing == false {
                isConfirmingRemoval = false
            }
        }
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var cardColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white.opacity(0.94)
    }

    private func toggleRemovalConfirmation() {
        isConfirmingRemoval.toggle()
    }

    private func confirmRemoval() {
        isConfirmingRemoval = false
        onRemoveFromCurrentGroup()
    }

    private func handlePlay() {
        guard isEditing == false else {
            return
        }
        onPlay()
    }
}
