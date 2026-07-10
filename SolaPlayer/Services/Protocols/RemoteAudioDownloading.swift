import Foundation

protocol RemoteAudioDownloading {
    func downloadAudio(from url: URL) async throws -> (URL, URLResponse)
}

extension URLSession: RemoteAudioDownloading {
    func downloadAudio(from url: URL) async throws -> (URL, URLResponse) {
        try await download(from: url)
    }
}
