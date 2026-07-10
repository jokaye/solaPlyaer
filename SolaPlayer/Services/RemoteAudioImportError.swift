import Foundation

enum RemoteAudioImportError: LocalizedError, Equatable {
    case invalidURL(String)
    case invalidResponse
    case httpStatus(Int)
    case unsupportedContentType(String?)

    var errorDescription: String? {
        switch self {
        case let .invalidURL(value):
            "请输入有效的 HTTP 或 HTTPS 音频链接：\(value)"
        case .invalidResponse:
            "服务器没有返回有效的 HTTP 响应。"
        case let .httpStatus(statusCode):
            "下载音频失败，服务器返回 HTTP \(statusCode)。"
        case let .unsupportedContentType(mimeType):
            "链接内容不是受支持的音频文件（\(mimeType ?? "未知类型")）。"
        }
    }
}
