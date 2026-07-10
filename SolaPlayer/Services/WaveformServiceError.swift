import Foundation

enum WaveformServiceError: LocalizedError {
    case invalidBucketCount
    case fileNotFound(String)
    case noAudioTrack
    case invalidAudioFormat
    case readerConfigurationFailed
    case readerStartFailed(String)
    case sampleReadFailed(String)
    case cacheRecoveryFailed(path: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidBucketCount:
            "波形采样桶数量必须大于零。"
        case let .fileNotFound(path):
            "无法生成波形，音频文件不存在：\(path)"
        case .noAudioTrack:
            "文件中没有可读取的音频轨道。"
        case .invalidAudioFormat:
            "无法读取音频的采样率或声道信息。"
        case .readerConfigurationFailed:
            "无法配置 PCM 音频读取器。"
        case let .readerStartFailed(reason):
            "波形分析无法启动：\(reason)"
        case let .sampleReadFailed(reason):
            "读取音频采样失败：\(reason)"
        case let .cacheRecoveryFailed(path, reason):
            "波形缓存损坏且无法重建：\(path)。\(reason)"
        }
    }
}
