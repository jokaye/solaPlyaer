import Foundation

protocol AudioImporting: Sendable {
    func importAudio(from sourceURL: URL) async throws -> ImportedAudio
    func removeImportedAudio(at localURL: URL) async throws
}
