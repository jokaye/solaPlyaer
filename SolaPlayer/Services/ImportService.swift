import AVFoundation
import Foundation
import UniformTypeIdentifiers

actor ImportService: AudioImporting {
    private let fileManager: FileManager
    private let destinationDirectory: URL
    private let remoteDownloader: any RemoteAudioDownloading

    init(
        destinationDirectory: URL? = nil,
        remoteDownloader: any RemoteAudioDownloading = URLSession.shared
    ) throws {
        let fileManager = FileManager()
        self.fileManager = fileManager
        self.remoteDownloader = remoteDownloader

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
        if sourceURL.isFileURL == false {
            return try await importRemoteAudio(from: sourceURL)
        }

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
                importedFiles.append(
                    try await importAudioFile(
                        from: sourceFile,
                        preferredFilename: nil,
                        bookmarkSourceURL: sourceFile
                    )
                )
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
        guard isManagedAudioURL(localURL) else {
            throw AudioImportError.unmanagedFile
        }
        guard fileManager.fileExists(atPath: localURL.path) else {
            return nil
        }

        try fileManager.createDirectory(at: deletionStagingDirectory, withIntermediateDirectories: true)
        let directoryURL = deletionStagingDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stagedURL = directoryURL.appendingPathComponent("payload", isDirectory: false)
        let metadataURL = directoryURL.appendingPathComponent("metadata.plist", isDirectory: false)

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        do {
            let metadata = StagedDeletionMetadata(originalPath: localURL.standardizedFileURL.path)
            let metadataData = try PropertyListEncoder().encode(metadata)
            try metadataData.write(to: metadataURL, options: .atomic)
            try fileManager.moveItem(at: localURL, to: stagedURL)
            return StagedAudioDeletion(
                originalURL: localURL,
                stagedURL: stagedURL,
                directoryURL: directoryURL
            )
        } catch let stagingError {
            do {
                try fileManager.removeItem(at: directoryURL)
            } catch let cleanupError {
                throw AudioImportError.cleanupFailed(
                    path: directoryURL.path,
                    reason: "\(stagingError.localizedDescription); \(cleanupError.localizedDescription)"
                )
            }
            throw stagingError
        }
    }

    func restoreStagedAudio(_ deletion: StagedAudioDeletion) async throws {
        if fileManager.fileExists(atPath: deletion.originalURL.path) {
            try removeStagingDirectoryIfPresent(deletion.directoryURL)
            return
        }
        guard fileManager.fileExists(atPath: deletion.stagedURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        try fileManager.moveItem(at: deletion.stagedURL, to: deletion.originalURL)
        try removeStagingDirectoryIfPresent(deletion.directoryURL)
    }

    func finalizeStagedAudioDeletion(_ deletion: StagedAudioDeletion) async throws {
        try await removeImportedAudio(at: deletion.originalURL)
        try removeStagingDirectoryIfPresent(deletion.directoryURL)
    }

    func reconcileStagedAudioDeletions(referencedLocalURLs: [URL]) async throws {
        guard fileManager.fileExists(atPath: deletionStagingDirectory.path) else {
            return
        }

        let referencedPaths = Set(referencedLocalURLs.map { $0.standardizedFileURL.path })
        let stagedDirectories = try fileManager.contentsOfDirectory(
            at: deletionStagingDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        for directoryURL in stagedDirectories {
            let values = try directoryURL.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let deletion = try stagedDeletion(in: directoryURL)
            if referencedPaths.contains(deletion.originalURL.standardizedFileURL.path) {
                try await restoreStagedAudio(deletion)
            } else {
                try await finalizeStagedAudioDeletion(deletion)
            }
        }

        if try fileManager.contentsOfDirectory(atPath: deletionStagingDirectory.path).isEmpty {
            try fileManager.removeItem(at: deletionStagingDirectory)
        }
    }

    private var deletionStagingDirectory: URL {
        destinationDirectory.appendingPathComponent(".Trash", isDirectory: true)
    }

    private func stagedDeletion(in directoryURL: URL) throws -> StagedAudioDeletion {
        guard directoryURL.deletingLastPathComponent().standardizedFileURL
            == deletionStagingDirectory.standardizedFileURL else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let metadataURL = directoryURL.appendingPathComponent("metadata.plist", isDirectory: false)
        let stagedURL = directoryURL.appendingPathComponent("payload", isDirectory: false)
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try PropertyListDecoder().decode(
            StagedDeletionMetadata.self,
            from: metadataData
        )
        let originalURL = URL(fileURLWithPath: metadata.originalPath).standardizedFileURL
        guard isManagedAudioURL(originalURL) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return StagedAudioDeletion(
            originalURL: originalURL,
            stagedURL: stagedURL,
            directoryURL: directoryURL
        )
    }

    private func isManagedAudioURL(_ url: URL) -> Bool {
        url.standardizedFileURL.deletingLastPathComponent()
            == destinationDirectory.standardizedFileURL
    }

    private func removeStagingDirectoryIfPresent(_ directoryURL: URL) throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }
        try fileManager.removeItem(at: directoryURL)
    }

    private func importRemoteAudio(from sourceURL: URL) async throws -> [ImportedAudio] {
        guard let scheme = sourceURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw RemoteAudioImportError.invalidURL(sourceURL.absoluteString)
        }

        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        let (temporaryURL, response) = try await remoteDownloader.downloadAudio(from: sourceURL)
        try Task.checkCancellation()
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteAudioImportError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RemoteAudioImportError.httpStatus(httpResponse.statusCode)
        }

        let filename = try remoteFilename(sourceURL: sourceURL, response: response)
        return [
            try await importAudioFile(
                from: temporaryURL,
                preferredFilename: filename,
                bookmarkSourceURL: nil
            ),
        ]
    }

    private func remoteFilename(sourceURL: URL, response: URLResponse) throws -> String {
        let candidates = [response.suggestedFilename, sourceURL.lastPathComponent]
            .compactMap { $0 }

        for candidate in candidates {
            let sanitized = URL(fileURLWithPath: candidate).lastPathComponent
            let fileExtension = URL(fileURLWithPath: sanitized).pathExtension
            if let type = UTType(filenameExtension: fileExtension), type.conforms(to: .audio) {
                return sanitized
            }
        }

        if let mimeType = response.mimeType,
           let type = UTType(mimeType: mimeType),
           type.conforms(to: .audio),
           let fileExtension = type.preferredFilenameExtension {
            let baseName = candidates
                .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
                .first(where: { $0.isEmpty == false }) ?? "remote-audio"
            return "\(baseName).\(fileExtension)"
        }

        throw RemoteAudioImportError.unsupportedContentType(response.mimeType)
    }

    private func importAudioFile(
        from sourceURL: URL,
        preferredFilename: String?,
        bookmarkSourceURL: URL?
    ) async throws -> ImportedAudio {
        let filenameURL = URL(fileURLWithPath: preferredFilename ?? sourceURL.lastPathComponent)
        let title = filenameURL.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw AudioImportError.emptyTitle
        }

        let destinationURL = uniqueDestination(fileExtension: filenameURL.pathExtension)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        do {
            let bookmarkURL = bookmarkSourceURL ?? destinationURL
            let bookmark = try bookmarkURL.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
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

    private func uniqueDestination(fileExtension: String) -> URL {
        let filename = fileExtension.isEmpty
            ? UUID().uuidString
            : "\(UUID().uuidString).\(fileExtension)"
        return destinationDirectory.appendingPathComponent(filename, isDirectory: false)
    }
}
