import Foundation

enum LibraryStoreError: LocalizedError, Equatable {
    case noFilesSelected
    case emptyGroupName
    case duplicateGroupName
    case groupNotFound
    case itemNotFound
    case emptyTrackTitle
    case invalidPaletteKey
    case membershipNotFound
    case fileCleanupFailed(path: String, reason: String)
    case recoveryFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .noFilesSelected:
            "没有选择任何音频文件。"
        case .emptyGroupName:
            "分组名称不能为空。"
        case .duplicateGroupName:
            "已经存在同名分组。"
        case .groupNotFound:
            "分组已不存在，请刷新后重试。"
        case .itemNotFound:
            "音频已不存在，请刷新后重试。"
        case .emptyTrackTitle:
            "音频标题不能为空。"
        case .invalidPaletteKey:
            "分组颜色无效。"
        case .membershipNotFound:
            "该音频已不在当前分组中。"
        case let .fileCleanupFailed(path, reason):
            "数据已更新，但文件清理失败：\(path)（\(reason)）"
        case let .recoveryFailed(reason):
            "保存失败后无法恢复音库状态：\(reason)"
        }
    }
}
