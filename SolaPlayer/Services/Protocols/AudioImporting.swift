import Foundation

protocol AudioImporting: Sendable {
    func importAudio(from sourceURL: URL) async throws -> [ImportedAudio]
    func removeImportedAudio(at localURL: URL) async throws
    func stageImportedAudioForDeletion(at localURL: URL) async throws -> StagedAudioDeletion?
    func restoreStagedAudio(_ deletion: StagedAudioDeletion) async throws
    func finalizeStagedAudioDeletion(_ deletion: StagedAudioDeletion) async throws
    func reconcileStagedAudioDeletions(referencedLocalURLs: [URL]) async throws
}
