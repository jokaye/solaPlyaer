import Foundation
import Testing
@testable import SolaPlayer

struct RemoteAudioImportValidationTests {
    @Test("远程导入拒绝非 HTTP 协议且不创建文件")
    func rejectsUnsupportedScheme() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let service = try ImportService(destinationDirectory: directory)
        let url = try #require(URL(string: "ftp://example.com/audio.mp3"))

        do {
            _ = try await service.importAudio(from: url)
            Issue.record("预期拒绝非 HTTP/HTTPS 链接。")
        } catch let error as RemoteAudioImportError {
            guard case .invalidURL = error else {
                Issue.record("收到远程导入错误，但类型不正确。")
                return
            }
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        #expect(FileManager.default.fileExists(atPath: directory.path) == false)
    }
}
