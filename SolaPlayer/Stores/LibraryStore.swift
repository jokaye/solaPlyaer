import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class LibraryStore {
    private let persistence: any LibraryPersisting
    private let importer: any AudioImporting

    private(set) var items: [AudioItem] = []
    private(set) var groups: [AudioGroup] = []
    private(set) var isImporting = false
    private(set) var pendingRemoval: MembershipRemoval?

    var scope: PlaybackScope = .master

    init(persistence: any LibraryPersisting, importer: any AudioImporting) throws {
        self.persistence = persistence
        self.importer = importer
        try reload()
    }

    var visibleItems: [AudioItem] {
        items(in: scope)
    }

    var scopeName: String {
        switch scope {
        case .master:
            "默认列表"
        case let .group(id):
            groups.first(where: { $0.id == id })?.name ?? "已删除分组"
        }
    }

    func reload() throws {
        items = try persistence.fetchAudioItems()
        groups = try persistence.fetchGroups()
    }

    func setScope(_ newScope: PlaybackScope) throws {
        if case let .group(id) = newScope,
           groups.contains(where: { $0.id == id }) == false {
            throw LibraryStoreError.groupNotFound
        }
        scope = newScope
    }

    func items(in scope: PlaybackScope) -> [AudioItem] {
        switch scope {
        case .master:
            items.sorted {
                ($0.masterOrder, $0.createdAt) < ($1.masterOrder, $1.createdAt)
            }
        case let .group(groupID):
            guard let group = groups.first(where: { $0.id == groupID }) else {
                return []
            }
            return group.memberships
                .sorted { ($0.orderInGroup, $0.addedAt) < ($1.orderInGroup, $1.addedAt) }
                .map(\.item)
        }
    }

    func membershipCount(for item: AudioItem) -> Int {
        item.memberships.count
    }

    func isMember(_ item: AudioItem, of group: AudioGroup) -> Bool {
        group.memberships.contains(where: { $0.item.id == item.id })
    }

    func importFiles(_ urls: [URL]) async throws {
        guard urls.isEmpty == false else {
            throw LibraryStoreError.noFilesSelected
        }

        isImporting = true
        defer { isImporting = false }

        for url in urls {
            let importedFiles = try await importer.importAudio(from: url)
            var order = nextMasterOrder
            for imported in importedFiles {
                persistence.insert(
                    AudioItem(
                        title: imported.title,
                        bookmark: imported.bookmark,
                        localCopyURL: imported.localCopyURL,
                        duration: imported.duration,
                        masterOrder: order
                    )
                )
                order += 1
            }

            do {
                try saveAndReload()
            } catch let persistenceError {
                try await cleanupImportedFiles(importedFiles, after: persistenceError)
                throw persistenceError
            }
        }
    }

    func reconcilePendingFileDeletions() async throws {
        try await importer.reconcileStagedAudioDeletions(
            referencedLocalURLs: items.compactMap(\.localCopyURL)
        )
    }

    @discardableResult
    func createGroup(
        name: String,
        colorKey: String? = nil,
        adding items: [AudioItem] = []
    ) throws -> AudioGroup {
        let normalizedName = try validatedGroupName(name, excluding: nil)
        try validatePaletteKey(colorKey)
        var seenItemIDs = Set<UUID>()
        let uniqueItems = items.filter { seenItemIDs.insert($0.id).inserted }
        guard uniqueItems.allSatisfy({ item in self.items.contains(where: { $0.id == item.id }) }) else {
            throw LibraryStoreError.itemNotFound
        }

        let group = AudioGroup(
            name: normalizedName,
            colorKey: colorKey,
            chipOrder: nextGroupOrder
        )
        persistence.insert(group)
        for (index, item) in uniqueItems.enumerated() {
            persistence.insert(
                Membership(group: group, item: item, orderInGroup: index)
            )
        }
        try saveAndReload()
        return group
    }

    func renameGroup(_ group: AudioGroup, to name: String) throws {
        try ensureGroupExists(group)
        let normalizedName = try validatedGroupName(name, excluding: group.id)
        group.name = normalizedName
        try saveAndReload()
    }

    func setColor(_ colorKey: String?, for group: AudioGroup) throws {
        try ensureGroupExists(group)
        try validatePaletteKey(colorKey)
        group.colorKey = colorKey
        try saveAndReload()
    }

    func deleteGroup(_ group: AudioGroup) throws {
        try ensureGroupExists(group)
        if scope == .group(group.id) {
            scope = .master
        }
        persistence.delete(group)
        try saveAndReload()
    }

    func reorderGroups(fromOffsets: IndexSet, toOffset: Int) throws {
        var reordered = groups
        reordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (index, group) in reordered.enumerated() {
            group.chipOrder = index
        }
        try saveAndReload()
    }

    func add(_ item: AudioItem, to groups: [AudioGroup]) throws {
        try add([item], to: groups)
    }

    func add(_ items: [AudioItem], to groups: [AudioGroup]) throws {
        var seenItemIDs = Set<UUID>()
        let uniqueItems = items.filter { seenItemIDs.insert($0.id).inserted }
        var seenGroupIDs = Set<UUID>()
        let uniqueGroups = groups.filter { seenGroupIDs.insert($0.id).inserted }
        guard uniqueItems.allSatisfy({ item in self.items.contains(where: { $0.id == item.id }) }) else {
            throw LibraryStoreError.itemNotFound
        }
        guard uniqueGroups.allSatisfy({ group in self.groups.contains(where: { $0.id == group.id }) }) else {
            throw LibraryStoreError.groupNotFound
        }

        for group in uniqueGroups {
            var nextOrder = (group.memberships.map(\.orderInGroup).max() ?? -1) + 1
            for item in uniqueItems where isMember(item, of: group) == false {
                persistence.insert(
                    Membership(group: group, item: item, orderInGroup: nextOrder)
                )
                nextOrder += 1
            }
        }
        try saveAndReload()
    }

    func remove(_ items: [AudioItem], from group: AudioGroup) throws {
        try ensureGroupExists(group)
        guard items.allSatisfy({ item in self.items.contains(where: { $0.id == item.id }) }) else {
            throw LibraryStoreError.itemNotFound
        }
        let itemIDs = Set(items.map(\.id))
        let membershipsToRemove = group.memberships.filter { itemIDs.contains($0.item.id) }

        for membership in membershipsToRemove {
            persistence.delete(membership)
        }
        let remaining = group.memberships
            .filter { itemIDs.contains($0.item.id) == false }
            .sorted { ($0.orderInGroup, $0.addedAt) < ($1.orderInGroup, $1.addedAt) }
        for (index, membership) in remaining.enumerated() {
            membership.orderInGroup = index
        }

        try saveAndReload()
    }

    @discardableResult
    func remove(_ item: AudioItem, from group: AudioGroup) throws -> MembershipRemoval {
        try ensureGroupExists(group)
        try ensureItemExists(item)
        guard let membership = group.memberships.first(where: { $0.item.id == item.id }) else {
            throw LibraryStoreError.membershipNotFound
        }

        let removal = MembershipRemoval(
            itemID: item.id,
            groupID: group.id,
            orderInGroup: membership.orderInGroup,
            itemTitle: item.title
        )
        let remaining = group.memberships
            .filter { $0.id != membership.id }
            .sorted { ($0.orderInGroup, $0.addedAt) < ($1.orderInGroup, $1.addedAt) }
        for (index, remainingMembership) in remaining.enumerated() {
            remainingMembership.orderInGroup = index
        }

        persistence.delete(membership)
        try saveAndReload()
        pendingRemoval = removal
        return removal
    }

    func undoPendingRemoval() throws {
        guard let removal = pendingRemoval else {
            return
        }
        guard let group = groups.first(where: { $0.id == removal.groupID }) else {
            pendingRemoval = nil
            throw LibraryStoreError.groupNotFound
        }
        guard let item = items.first(where: { $0.id == removal.itemID }) else {
            pendingRemoval = nil
            throw LibraryStoreError.itemNotFound
        }
        guard isMember(item, of: group) == false else {
            pendingRemoval = nil
            return
        }

        for membership in group.memberships where membership.orderInGroup >= removal.orderInGroup {
            membership.orderInGroup += 1
        }
        persistence.insert(
            Membership(
                group: group,
                item: item,
                orderInGroup: removal.orderInGroup
            )
        )
        try saveAndReload()
        pendingRemoval = nil
    }

    func dismissPendingRemoval(id: UUID) {
        guard pendingRemoval?.id == id else {
            return
        }
        pendingRemoval = nil
    }

    func reorderItems(fromOffsets: IndexSet, toOffset: Int) throws {
        switch scope {
        case .master:
            var reordered = items(in: .master)
            reordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
            for (index, item) in reordered.enumerated() {
                item.masterOrder = index
            }
        case let .group(groupID):
            guard let group = groups.first(where: { $0.id == groupID }) else {
                throw LibraryStoreError.groupNotFound
            }
            var reordered = group.memberships.sorted {
                ($0.orderInGroup, $0.addedAt) < ($1.orderInGroup, $1.addedAt)
            }
            reordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
            for (index, membership) in reordered.enumerated() {
                membership.orderInGroup = index
            }
        }
        try saveAndReload()
    }

    func renameItem(_ item: AudioItem, to title: String) throws {
        try ensureItemExists(item)
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTitle.isEmpty == false else {
            throw LibraryStoreError.emptyTrackTitle
        }
        item.title = normalizedTitle
        try saveAndReload()
    }

    func deleteItem(_ item: AudioItem) async throws {
        try ensureItemExists(item)
        let stagedDeletion: StagedAudioDeletion?
        if let localCopyURL = item.localCopyURL {
            stagedDeletion = try await importer.stageImportedAudioForDeletion(at: localCopyURL)
        } else {
            stagedDeletion = nil
        }

        persistence.delete(item)
        do {
            try saveAndReload()
        } catch let persistenceError {
            if let stagedDeletion {
                do {
                    try await importer.restoreStagedAudio(stagedDeletion)
                } catch let restoreError {
                    throw LibraryStoreError.recoveryFailed(
                        reason: "\(persistenceError.localizedDescription); \(restoreError.localizedDescription)"
                    )
                }
            }
            throw persistenceError
        }

        if let stagedDeletion {
            do {
                try await importer.finalizeStagedAudioDeletion(stagedDeletion)
            } catch {
                throw LibraryStoreError.fileCleanupFailed(
                    path: stagedDeletion.stagedURL.path,
                    reason: error.localizedDescription
                )
            }
        }
    }

    private var nextMasterOrder: Int {
        (items.map(\.masterOrder).max() ?? -1) + 1
    }

    private var nextGroupOrder: Int {
        (groups.map(\.chipOrder).max() ?? -1) + 1
    }

    private func validatedGroupName(_ name: String, excluding groupID: UUID?) throws -> String {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.isEmpty == false else {
            throw LibraryStoreError.emptyGroupName
        }
        guard groups.contains(where: {
            $0.id != groupID && $0.name.localizedCaseInsensitiveCompare(normalizedName) == .orderedSame
        }) == false else {
            throw LibraryStoreError.duplicateGroupName
        }
        return normalizedName
    }

    private func ensureGroupExists(_ group: AudioGroup) throws {
        guard groups.contains(where: { $0.id == group.id }) else {
            throw LibraryStoreError.groupNotFound
        }
    }

    private func ensureItemExists(_ item: AudioItem) throws {
        guard items.contains(where: { $0.id == item.id }) else {
            throw LibraryStoreError.itemNotFound
        }
    }

    private func cleanupImportedFiles(
        _ importedFiles: [ImportedAudio],
        after persistenceError: Error
    ) async throws {
        var failures: [String] = []
        for importedFile in importedFiles {
            do {
                try await importer.removeImportedAudio(at: importedFile.localCopyURL)
            } catch {
                failures.append(error.localizedDescription)
            }
        }
        if failures.isEmpty == false {
            throw LibraryStoreError.fileCleanupFailed(
                path: importedFiles.map(\.localCopyURL.path).joined(separator: ", "),
                reason: "\(persistenceError.localizedDescription); \(failures.joined(separator: "; "))"
            )
        }
    }

    private func validatePaletteKey(_ colorKey: String?) throws {
        if let colorKey, AppPalette(rawValue: colorKey) == nil {
            throw LibraryStoreError.invalidPaletteKey
        }
    }

    private func saveAndReload() throws {
        do {
            try persistence.save()
            try reload()
        } catch let persistenceError {
            persistence.rollback()
            do {
                try reload()
            } catch {
                throw LibraryStoreError.recoveryFailed(reason: error.localizedDescription)
            }
            throw persistenceError
        }
    }
}
