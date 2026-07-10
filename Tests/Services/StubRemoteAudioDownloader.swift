import Foundation
@testable import SolaPlayer

struct StubRemoteAudioDownloader: RemoteAudioDownloading {
    let temporaryURL: URL
    let response: URLResponse

    func downloadAudio(from url: URL) async throws -> (URL, URLResponse) {
        (temporaryURL, response)
    }
}
