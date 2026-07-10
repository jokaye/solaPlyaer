import Foundation
import SwiftData
@testable import SolaPlayer

@MainActor
struct LibraryTestContext {
    let container: ModelContainer
    let store: LibraryStore
    let sourceURLs: [URL]

    init(titles: [String]) throws {
        let container = try AppModelContainer.make(inMemory: true)

        var imports: [URL: ImportedAudio] = [:]
        var sourceURLs: [URL] = []
        for (index, title) in titles.enumerated() {
            let sourceURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a")
            sourceURLs.append(sourceURL)
            imports[sourceURL] = ImportedAudio(
                title: title,
                bookmark: Data([UInt8(index)]),
                localCopyURL: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).m4a"),
                duration: TimeInterval(60 + index)
            )
        }

        let persistence = PersistenceService(modelContext: container.mainContext)
        let store = try LibraryStore(
            persistence: persistence,
            importer: StubAudioImporter(imports: imports)
        )

        self.container = container
        self.store = store
        self.sourceURLs = sourceURLs
    }
}
