import Foundation
import Observation

@MainActor
@Observable
final class PlayerStore {
    private let engine: any AudioPlaying
    private let waveformService: any WaveformProviding

    private(set) var queue: [PlaybackQueueItem] = []
    private(set) var currentIndex = 0
    private(set) var sourceName = "默认列表"
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying = false
    private(set) var isScrubbing = false
    private(set) var scrubDirection: ScrubDirection?
    private(set) var samples: [Float] = []
    private(set) var isWaveformLoading = false

    private var scrubProgress: Double?
    private var wasPlayingBeforeScrub = false
    private var pendingPlaybackError: Error?

    init(engine: any AudioPlaying, waveformService: any WaveformProviding) {
        self.engine = engine
        self.waveformService = waveformService
    }

    var currentItem: PlaybackQueueItem? {
        guard queue.indices.contains(currentIndex) else {
            return nil
        }
        return queue[currentIndex]
    }

    var displayedProgress: Double {
        if let scrubProgress {
            return scrubProgress
        }
        guard duration > 0 else {
            return 0
        }
        return min(max(currentTime / duration, 0), 1)
    }

    var displayedTime: TimeInterval {
        displayedProgress * duration
    }

    func start(
        queue: [PlaybackQueueItem],
        initialItemID: UUID,
        sourceName: String
    ) throws {
        guard queue.isEmpty == false else {
            throw PlayerStoreError.emptyQueue
        }
        guard let initialIndex = queue.firstIndex(where: { $0.id == initialItemID }) else {
            throw PlayerStoreError.itemNotFound
        }

        self.queue = queue
        currentIndex = initialIndex
        self.sourceName = sourceName
        try loadCurrent(autoplay: true)
    }

    func togglePlayback() throws {
        if engine.isPlaying {
            engine.pause()
            refreshPlaybackState()
            return
        }

        if duration > 0, currentTime >= duration - 0.05 {
            engine.seek(to: 0)
        }
        try engine.play()
        refreshPlaybackState()
    }

    func playNext() throws {
        guard queue.isEmpty == false else {
            throw PlayerStoreError.emptyQueue
        }
        let shouldResume = engine.isPlaying
        currentIndex = (currentIndex + 1) % queue.count
        try loadCurrent(autoplay: shouldResume)
    }

    func playPrevious() throws {
        guard queue.isEmpty == false else {
            throw PlayerStoreError.emptyQueue
        }
        if currentTime > 3 {
            seek(toProgress: 0)
            return
        }

        let shouldResume = engine.isPlaying
        currentIndex = (currentIndex - 1 + queue.count) % queue.count
        try loadCurrent(autoplay: shouldResume)
    }

    func playItem(id: UUID) throws {
        guard let requestedIndex = queue.firstIndex(where: { $0.id == id }) else {
            throw PlayerStoreError.itemNotFound
        }
        guard requestedIndex != currentIndex else {
            return
        }

        currentIndex = requestedIndex
        try loadCurrent(autoplay: true)
    }

    func updateScrubbing(to progress: Double) {
        let normalized = min(max(progress, 0), 1)
        let previousProgress = displayedProgress

        if isScrubbing == false {
            isScrubbing = true
            wasPlayingBeforeScrub = engine.isPlaying
            engine.pause()
        }

        if normalized > previousProgress {
            scrubDirection = .forward
        } else if normalized < previousProgress {
            scrubDirection = .backward
        }
        scrubProgress = normalized
        isPlaying = false
    }

    func completeScrubbing(at progress: Double) throws {
        updateScrubbing(to: progress)
        seek(toProgress: progress)
        scrubProgress = nil
        scrubDirection = nil
        isScrubbing = false

        if wasPlayingBeforeScrub {
            try engine.play()
        }
        wasPlayingBeforeScrub = false
        refreshPlaybackState()
    }

    func adjustTime(by seconds: TimeInterval) {
        guard duration > 0 else {
            return
        }
        let target = min(max(displayedTime + seconds, 0), duration)
        engine.seek(to: target)
        scrubProgress = nil
        refreshPlaybackState()
    }

    func seek(to time: TimeInterval) {
        guard duration > 0, time.isFinite else {
            return
        }
        let target = min(max(time, 0), duration)
        engine.seek(to: target)
        currentTime = target
        scrubProgress = nil
        scrubDirection = nil
        isScrubbing = false
        refreshPlaybackState()
    }

    func removeDeletedItem(id: UUID) {
        guard let removedIndex = queue.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removedCurrentItem = removedIndex == currentIndex
        let shouldResume = engine.isPlaying
        queue.remove(at: removedIndex)

        guard queue.isEmpty == false else {
            resetEmptyQueue()
            return
        }

        if removedCurrentItem {
            currentIndex = removedIndex % queue.count
            do {
                try loadCurrent(autoplay: shouldResume)
            } catch {
                pendingPlaybackError = error
            }
        } else if removedIndex < currentIndex {
            currentIndex -= 1
        }
    }

    func observeProgress() async throws {
        while true {
            try Task.checkCancellation()
            if let pendingPlaybackError {
                self.pendingPlaybackError = nil
                throw pendingPlaybackError
            }
            if let sessionError = engine.consumeSessionError() {
                throw sessionError
            }
            refreshPlaybackState()
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func loadWaveform() async throws {
        guard let item = currentItem else {
            throw PlayerStoreError.itemNotFound
        }
        guard let localCopyURL = item.localCopyURL else {
            throw PlayerStoreError.localCopyUnavailable(item.title)
        }

        let requestedItemID = item.id
        isWaveformLoading = true
        defer {
            if currentItem?.id == requestedItemID {
                isWaveformLoading = false
            }
        }

        let extractedSamples = try await waveformService.samples(
            for: localCopyURL,
            bucketCount: 72
        )
        try Task.checkCancellation()

        guard currentItem?.id == requestedItemID else {
            return
        }
        samples = extractedSamples
    }

    private func loadCurrent(autoplay: Bool) throws {
        guard let item = currentItem else {
            throw PlayerStoreError.itemNotFound
        }
        guard let localCopyURL = item.localCopyURL else {
            throw PlayerStoreError.localCopyUnavailable(item.title)
        }

        try engine.load(url: localCopyURL)
        currentTime = 0
        duration = engine.duration > 0 ? engine.duration : item.duration
        samples = placeholderSamples(for: item.id)
        scrubProgress = nil
        scrubDirection = nil
        isScrubbing = false

        if autoplay {
            try engine.play()
        }
        refreshPlaybackState()
    }

    private func seek(toProgress progress: Double) {
        let normalized = min(max(progress, 0), 1)
        engine.seek(to: normalized * duration)
        currentTime = normalized * duration
    }

    private func refreshPlaybackState() {
        currentTime = min(max(engine.currentTime, 0), duration)
        isPlaying = engine.isPlaying
    }

    private func resetEmptyQueue() {
        engine.stop()
        currentIndex = 0
        currentTime = 0
        duration = 0
        isPlaying = false
        isScrubbing = false
        scrubDirection = nil
        scrubProgress = nil
        wasPlayingBeforeScrub = false
        samples = []
        isWaveformLoading = false
    }

    private func placeholderSamples(for id: UUID) -> [Float] {
        let seed = id.uuidString.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        return (0..<72).map { index in
            let primary = abs(sin(Double(index + seed % 17) * 0.31))
            let secondary = abs(cos(Double(index + seed % 11) * 0.13))
            return Float(0.16 + (primary * 0.56) + (secondary * 0.24))
        }
    }
}
