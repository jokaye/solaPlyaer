import Foundation

enum TestFailure: LocalizedError, Equatable {
    case saveFailed
    case finalizationFailed
    case loadFailed
    case playFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            "模拟保存失败"
        case .finalizationFailed:
            "模拟文件清理失败"
        case .loadFailed:
            "模拟音频加载失败"
        case .playFailed:
            "模拟音频播放失败"
        }
    }
}
