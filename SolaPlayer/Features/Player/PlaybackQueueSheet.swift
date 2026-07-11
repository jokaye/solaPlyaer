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
                        .padding(.horizontal, AppSpacing.standard)
                        .padding(.vertical, 8)
                        .background(
                            item.id == currentItemID
                                ? AppPalette.lake.colors.middle.opacity(0.22)
                                : Color.white.opacity(0.9),
                            in: .rect(cornerRadius: 18)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(item.id == currentItemID ? "正在播放" : "")
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(LibraryBackground())
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
        .presentationBackground(.ultraThinMaterial)
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
