import Foundation
import SwiftData

@MainActor
final class PersistenceService: LibraryPersisting, MarkerPersisting {
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

    func delete(_ item: AudioItem) throws {
        for marker in try fetchMarkers(ownerID: item.id) {
            modelContext.delete(marker)
        }
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

    func containsAudioItem(id: UUID) throws -> Bool {
        let requestedID = id
        var descriptor = FetchDescriptor<AudioItem>(
            predicate: #Predicate { item in
                item.id == requestedID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetchCount(descriptor) > 0
    }

    func fetchMarkers(ownerID: UUID) throws -> [Marker] {
        let requestedOwnerID = ownerID
        return try modelContext.fetch(
            FetchDescriptor<Marker>(
                predicate: #Predicate { marker in
                    marker.ownerID == requestedOwnerID
                },
                sortBy: [SortDescriptor(\Marker.time), SortDescriptor(\Marker.createdAt)]
            )
        )
    }

    func insert(_ marker: Marker) {
        modelContext.insert(marker)
    }

    func delete(_ marker: Marker) {
        modelContext.delete(marker)
    }
}
