import SwiftData

@MainActor
final class PersistenceService: LibraryPersisting {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAudioItems() throws -> [AudioItem] {
        var descriptor = FetchDescriptor<AudioItem>(
            sortBy: [SortDescriptor(\AudioItem.masterOrder), SortDescriptor(\AudioItem.createdAt)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\AudioItem.memberships]
        return try modelContext.fetch(descriptor)
    }

    func fetchGroups() throws -> [AudioGroup] {
        var descriptor = FetchDescriptor<AudioGroup>(
            sortBy: [SortDescriptor(\AudioGroup.chipOrder), SortDescriptor(\AudioGroup.createdAt)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\AudioGroup.memberships]
        return try modelContext.fetch(descriptor)
    }

    func insert(_ item: AudioItem) {
        modelContext.insert(item)
    }

    func insert(_ group: AudioGroup) {
        modelContext.insert(group)
    }

    func insert(_ membership: Membership) {
        modelContext.insert(membership)
    }

    func delete(_ item: AudioItem) {
        modelContext.delete(item)
    }

    func delete(_ group: AudioGroup) {
        modelContext.delete(group)
    }

    func delete(_ membership: Membership) {
        modelContext.delete(membership)
    }

    func save() throws {
        try modelContext.save()
    }

    func rollback() {
        modelContext.rollback()
    }
}
