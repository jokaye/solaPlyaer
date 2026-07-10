import Foundation
@testable import SolaPlayer

struct StubAudioImporter: AudioImporting {
    let imports: [URL: ImportedAudio]

    func importAudio(from sourceURL: URL) async throws -> ImportedAudio {
        guard let importedAudio = imports[sourceURL] else {
            throw AudioImportError.unsupportedFile
        }
        return importedAudio
    }

    func removeImportedAudio(at localURL: URL) async throws {
    }
}
