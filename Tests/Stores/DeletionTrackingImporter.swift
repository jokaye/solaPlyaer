import Foundation
@testable import SolaPlayer

actor DeletionTrackingImporter: AudioImporting {
    let imports: [URL: ImportedAudio]
    private(set) var restoreCount = 0
    private(set) var finalizeCount = 0
    private(set) var purgeCount = 0
    let failFinalization: Bool

    init(imports: [URL: ImportedAudio], failFinalization: Bool = false) {
        self.imports = imports
        self.failFinalization = failFinalization
    }

    func importAudio(from sourceURL: URL) async throws -> [ImportedAudio] {
        guard let importedAudio = imports[sourceURL] else {
            throw AudioImportError.unsupportedFile
        }
        return [importedAudio]
    }

    func removeImportedAudio(at localURL: URL) async throws {
    }

    func stageImportedAudioForDeletion(at localURL: URL) async throws -> StagedAudioDeletion? {
        StagedAudioDeletion(
            originalURL: localURL,
            stagedURL: localURL.appendingPathExtension("staged")
        )
    }

    func restoreStagedAudio(_ deletion: StagedAudioDeletion) async throws {
        restoreCount += 1
    }

    func finalizeStagedAudioDeletion(_ deletion: StagedAudioDeletion) async throws {
        finalizeCount += 1
        if failFinalization {
            throw TestFailure.finalizationFailed
        }
    }

    func purgeStagedAudioDeletions() async throws {
        purgeCount += 1
    }
}
