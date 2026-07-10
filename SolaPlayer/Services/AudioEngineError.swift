import Foundation

enum AudioEngineError: LocalizedError {
    case localFileRequired
    case fileNotFound(String)
    case loadFailed
    case noLoadedAudio
    case playbackFailed
    case invalidSessionNotification
    case sessionRecoveryFailed(String)
    case sessionDeactivationFailed(String)

    var errorDescription: String? {
        switch self {
        case .localFileRequired:
            "播放器只能打开已导入到本地的音频。"
        case let .fileNotFound(path):
            "找不到音频文件：\(path)"
        case .loadFailed:
            "音频无法加载或格式不受支持。"
        case .noLoadedAudio:
            "当前没有已加载的音频。"
        case .playbackFailed:
            "音频播放启动失败。"
        case .invalidSessionNotification:
            "收到无法解析的音频会话状态通知。"
        case let .sessionRecoveryFailed(reason):
            "音频会话恢复失败：\(reason)"
        case let .sessionDeactivationFailed(reason):
            "音频会话停止失败：\(reason)"
        }
    }
}
