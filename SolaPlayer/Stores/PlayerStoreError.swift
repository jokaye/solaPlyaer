import Foundation

enum PlayerStoreError: LocalizedError {
    case emptyQueue
    case itemNotFound
    case localCopyUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .emptyQueue:
            "当前播放列表没有可播放的音频。"
        case .itemNotFound:
            "所选音频不在当前播放列表中。"
        case let .localCopyUnavailable(title):
            "“\(title)”没有可用的本地音频文件。"
        }
    }
}
