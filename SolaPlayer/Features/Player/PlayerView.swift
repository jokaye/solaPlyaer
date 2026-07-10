import SwiftUI

struct PlayerView: View {
    @Bindable var store: PlayerStore
    @Bindable var libraryStore: LibraryStore
    @Bindable var markerStore: MarkerStore
    @AppStorage(AppPreferenceKey.globalPalette) private var globalPaletteKey = AppPalette.clearSky.rawValue

    let queue: [PlaybackQueueItem]
    let initialItemID: UUID
    let sourceName: String

    @State private var itemForGrouping: AudioItem?
    @State private var presentedError: PresentedError?
    @State private var isShowingMarkers = false
    @State private var isShowingQueue = false

    var body: some View {
        ZStack {
            GradientBackground(palette: palette)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.displayedTime.durationText)
                        .appFont(AppTypography.playerTimeCode)
                        .contentTransition(.numericText())

                    Text("/ \(store.duration.durationText)")
                        .appFont(AppTypography.totalDuration)
                        .foregroundStyle(.white.secondary)

                    Text(store.currentItem?.title ?? "正在载入")
                        .appFont(AppTypography.playerTitle)
                        .lineLimit(2)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 2)

                Spacer(minLength: 80)

                if store.isScrubbing, let direction = store.scrubDirection {
                    Label(direction.label, systemImage: direction.systemImage)
                        .appFont(AppTypography.pill)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18), in: .capsule)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.opacity)
                }

                ZStack {
                    WaveformScrubber(
                        samples: store.samples,
                        progress: store.displayedProgress,
                        duration: store.duration,
                        markers: markerStore.markers,
                        isScrubbing: store.isScrubbing,
                        onChanged: { store.updateScrubbing(to: $0) },
                        onEnded: completeScrubbing,
                        onAdjustTime: { store.adjustTime(by: $0) }
                    )

                    if store.isWaveformLoading {
                        ProgressView("正在分析波形")
                            .tint(.white)
                            .appFont(AppTypography.metadata)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.12), in: .capsule)
                    }
                }
                .frame(height: 112)

                HStack {
                    Button("分组 \(membershipCount)", systemImage: "rectangle.3.group", action: showGroupPicker)
                        .disabled(currentLibraryItem == nil)
                        .frame(minHeight: 44)

                    Spacer()

                    Button(
                        "标记此刻 \(markerStore.markers.count)",
                        systemImage: "bookmark",
                        action: addMarker
                    )
                    .disabled(store.currentItem == nil || store.duration <= 0)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .frame(minHeight: 44)

                TransportControls(
                    isPlaying: store.isPlaying,
                    onPrevious: playPrevious,
                    onTogglePlayback: togglePlayback,
                    onNext: playNext
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
            .padding(.horizontal, AppSpacing.content)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.controls)
        }
        .foregroundStyle(.white)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: showQueue) {
                    HStack(spacing: 4) {
                        Text(store.sourceName)
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.white)
                .frame(minHeight: 44)
                .disabled(store.queue.isEmpty)
                .accessibilityHint("展开当前播放队列")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("标记列表", systemImage: "bookmark.fill", action: showMarkers)
                    .disabled(store.currentItem == nil)
            }
        }
        .sheet(item: $itemForGrouping) { item in
            GroupPickerSheet(store: libraryStore, items: [item])
        }
        .sheet(isPresented: $isShowingMarkers) {
            MarkerListView(store: markerStore, onSeek: seekToMarker)
        }
        .sheet(isPresented: $isShowingQueue) {
            PlaybackQueueSheet(
                sourceName: store.sourceName,
                queue: store.queue,
                currentItemID: store.currentItem?.id,
                onSelect: { try store.playItem(id: $0) }
            )
        }
        .alert(item: $presentedError) { error in
            Alert(title: Text("播放失败"), message: Text(error.message))
        }
        .task(id: initialItemID) {
            await runPlayer()
        }
        .task(id: store.currentItem?.id) {
            guard let currentItemID = store.currentItem?.id else {
                return
            }
            loadMarkers(for: currentItemID)
            await loadWaveform()
        }
    }

    private var palette: AppPalette {
        store.currentItem?.paletteKey
            .flatMap(AppPalette.init(rawValue:))
            ?? AppPalette(rawValue: globalPaletteKey)
            ?? .clearSky
    }

    private var currentLibraryItem: AudioItem? {
        guard let currentID = store.currentItem?.id else {
            return nil
        }
        return libraryStore.items.first(where: { $0.id == currentID })
    }

    private var membershipCount: Int {
        currentLibraryItem.map { libraryStore.membershipCount(for: $0) } ?? 0
    }

    private func runPlayer() async {
        do {
            try store.start(
                queue: queue,
                initialItemID: initialItemID,
                sourceName: sourceName
            )
        } catch {
            presentedError = PresentedError(error)
            return
        }

        while Task.isCancelled == false {
            do {
                try await store.observeProgress()
            } catch is CancellationError {
                return
            } catch {
                presentedError = PresentedError(error)
            }
        }
    }

    private func showGroupPicker() {
        itemForGrouping = currentLibraryItem
    }

    private func showMarkers() {
        isShowingMarkers = true
    }

    private func showQueue() {
        isShowingQueue = true
    }

    private func loadMarkers(for ownerID: UUID) {
        do {
            try markerStore.load(for: ownerID)
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func addMarker() {
        guard let ownerID = store.currentItem?.id else {
            presentedError = PresentedError(MarkerStoreError.audioItemNotFound)
            return
        }

        do {
            try markerStore.addMarker(
                for: ownerID,
                at: store.displayedTime,
                duration: store.duration
            )
            isShowingMarkers = true
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func seekToMarker(_ time: TimeInterval) {
        store.seek(to: time)
    }

    private func loadWaveform() async {
        do {
            try await store.loadWaveform()
        } catch is CancellationError {
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func completeScrubbing(_ progress: Double) {
        do {
            try store.completeScrubbing(at: progress)
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func togglePlayback() {
        perform(store.togglePlayback)
    }

    private func playPrevious() {
        perform(store.playPrevious)
    }

    private func playNext() {
        perform(store.playNext)
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            presentedError = PresentedError(error)
        }
    }
}
