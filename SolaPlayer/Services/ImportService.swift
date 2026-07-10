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

    func importAudio(from sourceURL: URL) async throws -> [ImportedAudio] {
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

        let sourceFiles = try audioFiles(at: sourceURL)
        var importedFiles: [ImportedAudio] = []

        do {
            for sourceFile in sourceFiles {
                importedFiles.append(try await importAudioFile(from: sourceFile))
            }
            return importedFiles
        } catch let importError {
            var cleanupFailures: [String] = []
            for importedFile in importedFiles {
                do {
                    try fileManager.removeItem(at: importedFile.localCopyURL)
                } catch {
                    cleanupFailures.append(error.localizedDescription)
                }
            }
            if cleanupFailures.isEmpty == false {
                throw AudioImportError.cleanupFailed(
                    path: destinationDirectory.path,
                    reason: "\(importError.localizedDescription); \(cleanupFailures.joined(separator: "; "))"
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

    func stageImportedAudioForDeletion(at localURL: URL) async throws -> StagedAudioDeletion? {
        guard fileManager.fileExists(atPath: localURL.path) else {
            return nil
        }

        try fileManager.createDirectory(at: deletionStagingDirectory, withIntermediateDirectories: true)
        let stagedURL = deletionStagingDirectory.appendingPathComponent(
            UUID().uuidString,
            conformingTo: .data
        )
        try fileManager.moveItem(at: localURL, to: stagedURL)
        return StagedAudioDeletion(originalURL: localURL, stagedURL: stagedURL)
    }

    func restoreStagedAudio(_ deletion: StagedAudioDeletion) async throws {
        guard fileManager.fileExists(atPath: deletion.stagedURL.path) else {
            return
        }
        guard fileManager.fileExists(atPath: deletion.originalURL.path) == false else {
            throw CocoaError(.fileWriteFileExists)
        }
        try fileManager.moveItem(at: deletion.stagedURL, to: deletion.originalURL)
    }

    func finalizeStagedAudioDeletion(_ deletion: StagedAudioDeletion) async throws {
        try await removeImportedAudio(at: deletion.stagedURL)
    }

    func purgeStagedAudioDeletions() async throws {
        guard fileManager.fileExists(atPath: deletionStagingDirectory.path) else {
            return
        }
        try fileManager.removeItem(at: deletionStagingDirectory)
    }

    private var deletionStagingDirectory: URL {
        destinationDirectory.appendingPathComponent(".Trash", isDirectory: true)
    }

    private func importAudioFile(from sourceURL: URL) async throws -> ImportedAudio {
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

    private func audioFiles(at url: URL) throws -> [URL] {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        guard resourceValues.isDirectory == true else {
            guard try isAudioFile(at: url) else {
                throw AudioImportError.unsupportedFile
            }
            return [url]
        }

        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .contentTypeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw AudioImportError.noAudioFilesInFolder
        }

        var audioFiles: [URL] = []
        for case let candidateURL as URL in enumerator {
            let candidateValues = try candidateURL.resourceValues(
                forKeys: [.isRegularFileKey, .contentTypeKey]
            )
            if candidateValues.isRegularFile == true,
               try isAudioFile(at: candidateURL) {
                audioFiles.append(candidateURL)
            }
        }
        if let enumerationError {
            throw enumerationError
        }
        guard audioFiles.isEmpty == false else {
            throw AudioImportError.noAudioFilesInFolder
        }
        return audioFiles.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    private func isAudioFile(at url: URL) throws -> Bool {
        let resourceType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
        let extensionType = UTType(filenameExtension: url.pathExtension)
        return resourceType?.conforms(to: .audio) == true || extensionType?.conforms(to: .audio) == true
    }

    private func uniqueDestination(for sourceURL: URL) -> URL {
        let fileExtension = sourceURL.pathExtension
        let filename = fileExtension.isEmpty
            ? UUID().uuidString
            : "\(UUID().uuidString).\(fileExtension)"
        return destinationDirectory.appendingPathComponent(filename, isDirectory: false)
    }
}
