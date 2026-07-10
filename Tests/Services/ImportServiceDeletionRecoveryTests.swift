import Foundation
import Testing
@testable import SolaPlayer

struct ImportServiceDeletionRecoveryTests {
    @Test("启动对账按数据库引用恢复或完成暂存删除")
    func reconciliationProtectsReferencedAudio() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let audioDirectory = directory.appendingPathComponent("Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Issue.record("无法清理测试目录：\(error.localizedDescription)")
            }
        }

        let service = try ImportService(destinationDirectory: audioDirectory)
        let audioURL = audioDirectory.appendingPathComponent("sample.m4a")
        try Data("audio".utf8).write(to: audioURL)

        let firstStage = try await service.stageImportedAudioForDeletion(at: audioURL)
        _ = try #require(firstStage)
        #expect(FileManager.default.fileExists(atPath: audioURL.path) == false)

        try await service.reconcileStagedAudioDeletions(referencedLocalURLs: [audioURL])
        #expect(FileManager.default.fileExists(atPath: audioURL.path))

        let secondStage = try await service.stageImportedAudioForDeletion(at: audioURL)
        _ = try #require(secondStage)
        try await service.reconcileStagedAudioDeletions(referencedLocalURLs: [])
        #expect(FileManager.default.fileExists(atPath: audioURL.path) == false)
    }

    @Test("数据库仍引用但暂存 payload 缺失时硬失败")
    func missingPayloadFailsRecovery() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let audioDirectory = directory.appendingPathComponent("Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Issue.record("无法清理测试目录：\(error.localizedDescription)")
            }
        }

        let service = try ImportService(destinationDirectory: audioDirectory)
        let audioURL = audioDirectory.appendingPathComponent("sample.m4a")
        try Data("audio".utf8).write(to: audioURL)
        let stagedDeletion = try await service.stageImportedAudioForDeletion(at: audioURL)
        let deletion = try #require(stagedDeletion)
        try FileManager.default.removeItem(at: deletion.stagedURL)

        do {
            try await service.reconcileStagedAudioDeletions(referencedLocalURLs: [audioURL])
            Issue.record("预期缺失 payload 时恢复失败。")
        } catch let error as CocoaError {
            #expect(error.code == .fileNoSuchFile)
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }
    }
}
