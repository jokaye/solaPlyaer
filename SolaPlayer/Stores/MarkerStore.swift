import Foundation
import Observation

@MainActor
@Observable
final class MarkerStore {
    private let persistence: any MarkerPersisting

    private(set) var markers: [Marker] = []
    private(set) var ownerID: UUID?

    init(persistence: any MarkerPersisting) {
        self.persistence = persistence
    }

    func load(for ownerID: UUID) throws {
        do {
            let fetchedMarkers = try persistence.fetchMarkers(ownerID: ownerID)
            self.ownerID = ownerID
            markers = fetchedMarkers
        } catch {
            self.ownerID = nil
            markers = []
            throw error
        }
    }

    @discardableResult
    func addMarker(
        for ownerID: UUID,
        at time: TimeInterval,
        duration: TimeInterval
    ) throws -> Marker {
        guard try persistence.containsAudioItem(id: ownerID) else {
            throw MarkerStoreError.audioItemNotFound
        }
        guard time.isFinite, duration.isFinite, duration > 0, (0...duration).contains(time) else {
            throw MarkerStoreError.invalidTime
        }

        let existingMarkers = try persistence.fetchMarkers(ownerID: ownerID)
        let marker = Marker(
            ownerID: ownerID,
            time: time,
            title: "标记 \(existingMarkers.count + 1)"
        )
        persistence.insert(marker)
        try saveAndReload(ownerID: ownerID)
        return marker
    }

    func update(_ marker: Marker, title: String, note: String) throws {
        try ensureCurrent(marker)
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTitle.isEmpty == false else {
            throw MarkerStoreError.emptyTitle
        }

        marker.title = normalizedTitle
        marker.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try saveAndReload(ownerID: marker.ownerID)
    }

    func delete(_ marker: Marker) throws {
        try ensureCurrent(marker)
        let markerOwnerID = marker.ownerID
        persistence.delete(marker)
        try saveAndReload(ownerID: markerOwnerID)
    }

    func handleDeletedAudio(id: UUID) {
        guard ownerID == id else {
            return
        }
        ownerID = nil
        markers = []
    }

    private func ensureCurrent(_ marker: Marker) throws {
        guard ownerID == marker.ownerID,
              markers.contains(where: { $0.id == marker.id }) else {
            throw MarkerStoreError.markerNotFound
        }
    }

    private func saveAndReload(ownerID: UUID) throws {
        do {
            try persistence.save()
            try load(for: ownerID)
        } catch let persistenceError {
            persistence.rollback()
            do {
                try load(for: ownerID)
            } catch {
                throw MarkerStoreError.recoveryFailed(error.localizedDescription)
            }
            throw persistenceError
        }
    }
}
