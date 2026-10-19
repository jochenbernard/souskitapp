import Foundation
import RecipeLibrary

/// Reads a recipe's text, fetching it from iCloud where it is not on the device.
struct RecipeTextReader: Sendable {
    /// What reading a recipe returns.
    struct Contents: Sendable {
        /// The recipe's text.
        let text: String

        /// When the contents read last changed, or `nil` where the file does not tell.
        let modificationDate: Date?
    }

    private let queue: OperationQueue
    private let recipeDirectory: RecipeDirectory
    private let startDownloading: @Sendable (URL) throws -> Void

    /// Creates a reader, which reads one file at a time.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory the recipes sit in.
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
        readQueue.maxConcurrentOperationCount = 1
        readQueue.qualityOfService = qualityOfService

        self.queue = readQueue
        self.recipeDirectory = recipeDirectory
        self.startDownloading = startDownloading
    }

    /// Reads a recipe.
    ///
    /// A recipe held only in iCloud is fetched first, and the call returns once the text is on the device, so it
    /// takes as long as that fetch does. Cancelling the task gives up on the read.
    ///
    /// - Parameters:
    ///   - fileName: The file's name inside the recipe directory, extension included.
    ///   - availability: Whether the file's contents are on the device.
    /// - Returns: The recipe's contents.
    /// - Throws: Whatever fetching or reading the file throws, or `CancellationError` when the task is cancelled.
    func read(fileName: String, availability: RecipeAvailability) async throws -> Contents {
        let url = recipeDirectory.url.appending(path: fileName)

        return try await recipeDirectory.url.withSecurityScope {
            if availability != .downloaded {
                // The coordinated read reports a fetch that cannot start, and waits for one that can.
                try? startDownloading(url)
            }

            return try await CancellableFileCoordination.read(at: url, queue: queue) { coordinatedURL in
                Contents(
                    text: try String(contentsOf: coordinatedURL, encoding: .utf8),
                    modificationDate: try? coordinatedURL.resourceValues(
                        forKeys: [.contentModificationDateKey]
                    ).contentModificationDate
                )
            }
        }
    }
}
