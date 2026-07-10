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

    @Test("越界删除元数据被拒绝且不会删除其他文件")
    func outOfBoundsMetadataCannotDeleteFiles() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let audioDirectory = directory.appendingPathComponent("Audio", isDirectory: true)
        let stagedDirectory = audioDirectory
            .appendingPathComponent(".Trash", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: stagedDirectory, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Issue.record("无法清理测试目录：\(error.localizedDescription)")
            }
        }

        let protectedURL = directory.appendingPathComponent("must-not-delete.txt")
        try Data("protected".utf8).write(to: protectedURL)
        let metadata = StagedDeletionMetadata(originalPath: protectedURL.path)
        let metadataData = try PropertyListEncoder().encode(metadata)
        try metadataData.write(
            to: stagedDirectory.appendingPathComponent("metadata.plist"),
            options: .atomic
        )
        try Data("payload".utf8).write(
            to: stagedDirectory.appendingPathComponent("payload")
        )

        let service = try ImportService(destinationDirectory: audioDirectory)
        do {
            try await service.reconcileStagedAudioDeletions(referencedLocalURLs: [])
            Issue.record("预期越界元数据被拒绝。")
        } catch let error as CocoaError {
            #expect(error.code == .fileReadCorruptFile)
        } catch {
            Issue.record("收到错误类型不正确：\(error.localizedDescription)")
        }

        #expect(FileManager.default.fileExists(atPath: protectedURL.path))
    }
}
