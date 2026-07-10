import SwiftUI

struct TransportControls: View {
    let isPlaying: Bool
    let onPrevious: () -> Void
    let onTogglePlayback: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 40) {
            Button("上一首", systemImage: "backward.fill", action: onPrevious)
                .font(.title3)
                .frame(width: 44, height: 44)

            Button(
                isPlaying ? "暂停" : "播放",
                systemImage: isPlaying ? "pause.fill" : "play.fill",
                action: onTogglePlayback
            )
            .font(.system(size: 28))
            .frame(width: 44, height: 44)

            Button("下一首", systemImage: "forward.fill", action: onNext)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}
