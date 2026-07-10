import SwiftUI

struct PlaybackQueueSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sourceName: String
    let queue: [PlaybackQueueItem]
    let currentItemID: UUID?
    let onSelect: (UUID) throws -> Void

    @State private var presentedError: PresentedError?

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(queue.enumerated()), id: \.element.id) { index, item in
                    Button(action: { select(item) }) {
                        HStack(spacing: AppSpacing.standard) {
                            Text("\(index + 1)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 28, alignment: .trailing)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(item.duration.durationText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if item.id == currentItemID {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(AppColor.ink)
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityValue(item.id == currentItemID ? "正在播放" : "")
                }
            }
            .navigationTitle(sourceName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: dismiss.callAsFunction)
                }
            }
            .alert(item: $presentedError) { error in
                Alert(title: Text("无法播放所选音频"), message: Text(error.message))
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func select(_ item: PlaybackQueueItem) {
        do {
            try onSelect(item.id)
            dismiss()
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
