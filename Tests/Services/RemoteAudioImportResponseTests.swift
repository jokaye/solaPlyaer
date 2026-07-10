import Foundation
import Testing
@testable import SolaPlayer

struct RemoteAudioImportResponseTests {
    @Test("远程导入拒绝非 2xx HTTP 响应", .tags(.networking))
    func rejectsHTTPFailureStatus() async throws {
        let sourceURL = try #require(URL(string: "https://example.com/audio.mp3"))
        let fixture = try makeFixture(
            sourceURL: sourceURL,
            statusCode: 503,
            mimeType: "audio/mpeg"
        )
        defer { removeFixture(fixture.root) }

        do {
            _ = try await fixture.service.importAudio(from: sourceURL)
            Issue.record("预期拒绝 HTTP 503。")
        } catch let error as RemoteAudioImportError {
            #expect(error == .httpStatus(503))
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        let importedFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.destinationDirectory,
            includingPropertiesForKeys: nil
        )
        #expect(importedFiles.isEmpty)
    }

    @Test("远程导入拒绝无音频扩展名的非音频响应", .tags(.networking))
    func rejectsNonAudioResponse() async throws {
        let sourceURL = try #require(URL(string: "https://example.com/download"))
        let fixture = try makeFixture(
            sourceURL: sourceURL,
            statusCode: 200,
            mimeType: "text/plain"
        )
        defer { removeFixture(fixture.root) }

        do {
            _ = try await fixture.service.importAudio(from: sourceURL)
            Issue.record("预期拒绝非音频响应。")
        } catch let error as RemoteAudioImportError {
            #expect(error == .unsupportedContentType("text/plain"))
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        let importedFiles = try FileManager.default.contentsOfDirectory(
            at: fixture.destinationDirectory,
            includingPropertiesForKeys: nil
        )
        #expect(importedFiles.isEmpty)
    }

    private func makeFixture(
        sourceURL: URL,
        statusCode: Int,
        mimeType: String
    ) throws -> (
        root: URL,
        destinationDirectory: URL,
        service: ImportService
    ) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destinationDirectory = root.appendingPathComponent("Audio", isDirectory: true)
        let downloadedFile = root.appendingPathComponent("download")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("response body".utf8).write(to: downloadedFile)
        let response = try #require(
            HTTPURLResponse(
                url: sourceURL,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": mimeType]
            )
        )
        let downloader = StubRemoteAudioDownloader(
            temporaryURL: downloadedFile,
            response: response
        )
        let service = try ImportService(
            destinationDirectory: destinationDirectory,
            remoteDownloader: downloader
        )
        return (root, destinationDirectory, service)
    }

    private func removeFixture(_ root: URL) {
        do {
            try FileManager.default.removeItem(at: root)
        } catch {
            Issue.record("无法清理远程导入测试目录：\(error.localizedDescription)")
        }
    }
}
