import Foundation

enum AudioImportError: LocalizedError, Equatable {
    case unsupportedFile
    case destinationUnavailable
    case emptyTitle
    case invalidDuration
    case cleanupFailed(path: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "请选择有效的音频文件。"
        case .destinationUnavailable:
            "无法访问应用的音频存储目录。"
        case .emptyTitle:
            "音频文件名不能为空。"
        case .invalidDuration:
            "无法读取该音频的有效时长。"
        case let .cleanupFailed(path, reason):
            "导入失败，且无法清理临时文件：\(path)（\(reason)）"
        }
    }
}
