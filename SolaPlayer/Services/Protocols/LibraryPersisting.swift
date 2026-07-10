import Foundation

@MainActor
protocol LibraryPersisting {
    func fetchAudioItems() throws -> [AudioItem]
    func fetchGroups() throws -> [AudioGroup]

    func insert(_ item: AudioItem)
    func insert(_ group: AudioGroup)
    func insert(_ membership: Membership)

    func delete(_ item: AudioItem)
    func delete(_ group: AudioGroup)
    func delete(_ membership: Membership)

    func save() throws
    func rollback()
}
