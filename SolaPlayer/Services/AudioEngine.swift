import AVFoundation
import Foundation

@MainActor
final class AudioEngine: AudioPlaying {
    private var player: AVAudioPlayer?
    private let notificationCenter: NotificationCenter
    private var observerTokens: [NSObjectProtocol] = []
    private var shouldResumeAfterInterruption = false
    private var pendingSessionError: Error?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        observeAudioSession()
    }

    deinit {
        for token in observerTokens {
            notificationCenter.removeObserver(token)
        }
    }

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    func load(url: URL) throws {
        guard url.isFileURL else {
            throw AudioEngineError.localFileRequired
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioEngineError.fileNotFound(url.path)
        }

        player?.stop()
        let nextPlayer = try AVAudioPlayer(contentsOf: url)
        guard nextPlayer.prepareToPlay() else {
            throw AudioEngineError.loadFailed
        }
        player = nextPlayer
    }

    func play() throws {
        guard let player else {
            throw AudioEngineError.noLoadedAudio
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        guard player.play() else {
            throw AudioEngineError.playbackFailed
        }
        pendingSessionError = nil
    }

    func pause() {
        player?.pause()
    }

    func seek(to time: TimeInterval) {
        guard let player else {
            return
        }
        player.currentTime = min(max(time, 0), player.duration)
    }

    func stop() {
        player?.stop()
        player = nil
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            pendingSessionError = AudioEngineError.sessionDeactivationFailed(
                error.localizedDescription
            )
        }
    }

    func consumeSessionError() -> Error? {
        defer { pendingSessionError = nil }
        return pendingSessionError
    }

    private func observeAudioSession() {
        let session = AVAudioSession.sharedInstance()
        observerTokens.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleInterruption(notification)
                }
            }
        )
        observerTokens.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.handleRouteChange(notification)
                }
            }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: rawType) else {
            pendingSessionError = AudioEngineError.invalidSessionNotification
            return
        }

        switch interruptionType {
        case .began:
            shouldResumeAfterInterruption = player?.isPlaying == true
            player?.pause()
        case .ended:
            defer { shouldResumeAfterInterruption = false }
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            guard shouldResumeAfterInterruption, options.contains(.shouldResume) else {
                return
            }

            do {
                try AVAudioSession.sharedInstance().setActive(true)
                guard player?.play() == true else {
                    throw AudioEngineError.playbackFailed
                }
            } catch {
                if let engineError = error as? AudioEngineError {
                    pendingSessionError = engineError
                } else {
                    pendingSessionError = AudioEngineError.sessionRecoveryFailed(
                        error.localizedDescription
                    )
                }
            }
        @unknown default:
            pendingSessionError = AudioEngineError.invalidSessionNotification
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else {
            pendingSessionError = AudioEngineError.invalidSessionNotification
            return
        }
        guard reason == .oldDeviceUnavailable else {
            return
        }
        player?.pause()
    }
}
