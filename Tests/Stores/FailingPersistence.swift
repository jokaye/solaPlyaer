import Foundation
@testable import SolaPlayer

@MainActor
final class FailingPersistence: LibraryPersisting {
    private let base: any LibraryPersisting
    var failNextSave = false

    init(base: any LibraryPersisting) {
        self.base = base
    }

    func fetchAudioItems() throws -> [AudioItem] {
        try base.fetchAudioItems()
    }

    func fetchGroups() throws -> [AudioGroup] {
        try base.fetchGroups()
    }

    func insert(_ item: AudioItem) {
        base.insert(item)
    }

    func insert(_ group: AudioGroup) {
        base.insert(group)
    }

    func insert(_ membership: Membership) {
        base.insert(membership)
    }

    func delete(_ item: AudioItem) throws {
        try base.delete(item)
    }

    func delete(_ group: AudioGroup) {
        base.delete(group)
    }

    func delete(_ membership: Membership) {
        base.delete(membership)
    }

    func save() throws {
        if failNextSave {
            failNextSave = false
            throw TestFailure.saveFailed
        }
        try base.save()
    }

    func rollback() {
        base.rollback()
    }
}
