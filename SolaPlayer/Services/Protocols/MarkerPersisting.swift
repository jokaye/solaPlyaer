import Foundation

@MainActor
protocol MarkerPersisting {
    func containsAudioItem(id: UUID) throws -> Bool
    func fetchMarkers(ownerID: UUID) throws -> [Marker]
    func insert(_ marker: Marker)
    func delete(_ marker: Marker)
    func save() throws
    func rollback()
}
