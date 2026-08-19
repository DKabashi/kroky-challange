import CryptoKit
import Foundation

protocol VideoCaching: Sendable {
    func localURL(for resource: VideoResource) async throws -> URL
    func prefetch(_ resources: [VideoResource]) async
    func remove(_ resource: VideoResource) async
}

actor RemoteVideoCache: VideoCaching {
    static let shared = RemoteVideoCache()

    private let session: URLSession
    private let maximumConcurrentPrefetches: Int
    private var inFlight: [VideoResource: Task<URL, Error>] = [:]

    init(
        session: URLSession? = nil,
        maximumConcurrentPrefetches: Int = 2
    ) {
        self.maximumConcurrentPrefetches = max(maximumConcurrentPrefetches, 1)

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.allowsCellularAccess = true
            configuration.allowsConstrainedNetworkAccess = true
            configuration.allowsExpensiveNetworkAccess = true
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 120
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
    }

    func localURL(for resource: VideoResource) async throws -> URL {
        let destination = try cachedFileURL(for: resource)

        if isUsableFile(at: destination) {
            return destination
        }

        if let existingTask = inFlight[resource] {
            return try await existingTask.value
        }

        let task = Task { [weak self] in
            guard let self else { throw CancellationError() }
            return try await self.download(resource, to: destination)
        }
        inFlight[resource] = task

        do {
            let localURL = try await task.value
            inFlight[resource] = nil
            return localURL
        } catch {
            inFlight[resource] = nil
            throw error
        }
    }

    func prefetch(_ resources: [VideoResource]) async {
        let uniqueResources = resources.reduce(into: [VideoResource]()) { result, resource in
            guard !result.contains(resource) else { return }
            result.append(resource)
        }

        guard let first = uniqueResources.first else { return }

        // Finish the opening clip first so the workout can start as soon as possible.
        _ = try? await localURL(for: first)

        var remaining = Array(uniqueResources.dropFirst()).makeIterator()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<min(maximumConcurrentPrefetches, uniqueResources.count - 1) {
                guard let resource = remaining.next() else { break }
                group.addTask { [weak self] in
                    _ = try? await self?.localURL(for: resource)
                }
            }

            while await group.next() != nil {
                guard let resource = remaining.next() else { continue }
                group.addTask { [weak self] in
                    _ = try? await self?.localURL(for: resource)
                }
            }
        }
    }

    func remove(_ resource: VideoResource) async {
        inFlight[resource]?.cancel()
        inFlight[resource] = nil

        guard let url = try? cachedFileURL(for: resource) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func download(_ resource: VideoResource, to destination: URL) async throws -> URL {
        let (temporaryURL, response) = try await session.download(from: resource.remoteURL)

        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw VideoCacheError.invalidResponse
        }

        guard response.mimeType?.hasPrefix("video/") == true else {
            throw VideoCacheError.unexpectedContentType(response.mimeType)
        }

        let resourceValues = try temporaryURL.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = resourceValues.fileSize, fileSize > 0 else {
            throw VideoCacheError.emptyDownload
        }

        if isUsableFile(at: destination) {
            return destination
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }

        do {
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            return destination
        } catch CocoaError.fileWriteFileExists {
            guard isUsableFile(at: destination) else { throw VideoCacheError.couldNotStoreFile }
            return destination
        } catch {
            throw VideoCacheError.couldNotStoreFile
        }
    }

    private func cachedFileURL(for resource: VideoResource) throws -> URL {
        let fileManager = FileManager.default
        let cachesDirectory = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let videoDirectory = cachesDirectory.appending(path: "KrokyVideoCache", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)

        let identity = "\(resource.version)|\(resource.remoteURL.absoluteString)"
        let digest = SHA256.hash(data: Data(identity.utf8))
        let fileName = digest.map { String(format: "%02x", $0) }.joined() + ".mp4"
        return videoDirectory.appending(path: fileName, directoryHint: .notDirectory)
    }

    private func isUsableFile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            return false
        }
        return fileSize > 0
    }
}

enum VideoCacheError: LocalizedError {
    case invalidResponse
    case unexpectedContentType(String?)
    case emptyDownload
    case couldNotStoreFile

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The video server returned an invalid response."
        case .unexpectedContentType:
            "The server response was not a video."
        case .emptyDownload:
            "The downloaded video was empty."
        case .couldNotStoreFile:
            "The video could not be stored on this device."
        }
    }
}
