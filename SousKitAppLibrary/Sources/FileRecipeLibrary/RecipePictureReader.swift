import Foundation
import RecipeLibrary

/// Reads the pictures recipes name, fetching them from iCloud where they are not on the device.
struct RecipePictureReader: Sendable {
    // Two at a time: decoding a large photo takes a while, and one waiting holds up no other.
    private static let concurrentReadCount = 2

    private let queue: OperationQueue
    private let recipeDirectory: RecipeDirectory
    private let startDownloading: @Sendable (URL) throws -> Void

    /// Creates a reader.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory the pictures sit in.
    ///   - qualityOfService: How urgent the reads are.
    ///   - startDownloading: Asks iCloud for a file's contents, returning before they arrive.
    init(
        recipeDirectory: RecipeDirectory,
        qualityOfService: QualityOfService,
        startDownloading: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    ) {
        let readQueue = OperationQueue()
        readQueue.maxConcurrentOperationCount = Self.concurrentReadCount
        readQueue.qualityOfService = qualityOfService

        self.queue = readQueue
        self.recipeDirectory = recipeDirectory
        self.startDownloading = startDownloading
    }

    /// Fetches a picture from iCloud, returning once it is on the device.
    ///
    /// Cancelling the task gives up on waiting, not on the fetch.
    ///
    /// - Parameter picture: The picture.
    /// - Throws: Whatever fetching the picture throws, or `CancellationError` when the task is cancelled.
    func fetch(_ picture: RecipePicture) async throws {
        try await read(picture) { _ in
            // Coordinating the read is what waits for the picture to land; nothing of it is read.
        }
    }

    /// Reads a picture, fetching it first where it is not on the device.
    ///
    /// Cancelling the task gives up on the read.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - read: Reads the picture's file at the URL it is handed.
    /// - Returns: What `read` returns.
    /// - Throws: Whatever fetching the picture or `read` throws, or `CancellationError` when the task is cancelled.
    func read<T: Sendable>(
        _ picture: RecipePicture,
        _ read: @escaping @Sendable (URL) throws -> T
    ) async throws -> T {
        let url = recipeDirectory.url.appending(path: picture.id)

        return try await recipeDirectory.url.withSecurityScope {
            if picture.availability != .downloaded {
                // The coordinated read reports a fetch that cannot start, and waits for one that can.
                try? startDownloading(url)
            }

            return try await CancellableFileCoordination.read(
                at: url,
                queue: queue,
                read
            )
        }
    }
}
