import SwiftUI

struct NowPlayingBar: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: PlaybackQueueItem
    let sourceName: String
    let isPlaying: Bool
    let onOpen: () -> Void
    let onTogglePlayback: () -> Void

    private var palette: AppPalette {
        item.paletteKey.flatMap(AppPalette.init(rawValue:)) ?? .clearSky
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    palette.gradient
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 13))
                        .overlay {
                            MiniWaveformView(seed: item.id)
                                .padding(7)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            Circle()
                                .fill(AppPalette.mint.colors.top)
                                .frame(width: 6, height: 6)
                            Text(sourceName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.lake.colors.top)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("返回播放页")

            Button(
                isPlaying ? "暂停" : "播放",
                systemImage: isPlaying ? "pause.fill" : "play.fill",
                action: onTogglePlayback
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(colorScheme == .dark ? Color.white : AppColor.ink, in: .circle)
            .foregroundStyle(colorScheme == .dark ? AppColor.ink : .white)
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.5), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
    }
}
