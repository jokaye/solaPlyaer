import AVFoundation
import Foundation
import UniformTypeIdentifiers

actor ImportService: AudioImporting {
    private let fileManager: FileManager
    private let destinationDirectory: URL

    init(fileManager: FileManager = .default, destinationDirectory: URL? = nil) throws {
        self.fileManager = fileManager

        if let destinationDirectory {
            self.destinationDirectory = destinationDirectory
        } else {
            guard let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw AudioImportError.destinationUnavailable
            }
            self.destinationDirectory = applicationSupport.appendingPathComponent("Audio", isDirectory: true)
        }
    }

    func importAudio(from sourceURL: URL) async throws -> ImportedAudio {
        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        let hasSecurityAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try validateAudioFile(at: sourceURL)

        let title = sourceURL.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw AudioImportError.emptyTitle
        }

        let bookmark = try sourceURL.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let destinationURL = uniqueDestination(for: sourceURL)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        do {
            let duration = try await AVURLAsset(url: destinationURL).load(.duration).seconds
            guard duration.isFinite, duration > 0 else {
                throw AudioImportError.invalidDuration
            }

            return ImportedAudio(
                title: title,
                bookmark: bookmark,
                localCopyURL: destinationURL,
                duration: duration
            )
        } catch let importError {
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch let cleanupError {
                throw AudioImportError.cleanupFailed(
                    path: destinationURL.path,
                    reason: "\(importError.localizedDescription); \(cleanupError.localizedDescription)"
                )
            }
            throw importError
        }
    }

    func removeImportedAudio(at localURL: URL) async throws {
        guard fileManager.fileExists(atPath: localURL.path) else {
            return
        }
        try fileManager.removeItem(at: localURL)
    }

    private func validateAudioFile(at url: URL) throws {
        let resourceType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
        let extensionType = UTType(filenameExtension: url.pathExtension)
        let isAudio = resourceType?.conforms(to: .audio) == true || extensionType?.conforms(to: .audio) == true

        guard isAudio else {
            throw AudioImportError.unsupportedFile
        }
    }

    private func uniqueDestination(for sourceURL: URL) -> URL {
        let fileExtension = sourceURL.pathExtension
        let filename = fileExtension.isEmpty
            ? UUID().uuidString
            : "\(UUID().uuidString).\(fileExtension)"
        return destinationDirectory.appendingPathComponent(filename, isDirectory: false)
    }
}
