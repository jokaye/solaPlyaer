import Foundation

enum MarkerStoreError: LocalizedError {
    case audioItemNotFound
    case markerNotFound
    case invalidTime
    case emptyTitle
    case recoveryFailed(String)

    var errorDescription: String? {
        switch self {
        case .audioItemNotFound:
            "标记对应的音频不存在。"
        case .markerNotFound:
            "标记不存在或不属于当前音频。"
        case .invalidTime:
            "标记时间必须位于音频时长范围内。"
        case .emptyTitle:
            "标记名称不能为空。"
        case let .recoveryFailed(reason):
            "标记数据恢复失败：\(reason)"
        }
    }
}
