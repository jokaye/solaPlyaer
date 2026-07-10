import Foundation

enum TestFailure: LocalizedError, Equatable {
    case saveFailed
    case finalizationFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            "模拟保存失败"
        case .finalizationFailed:
            "模拟文件清理失败"
        }
    }
}
