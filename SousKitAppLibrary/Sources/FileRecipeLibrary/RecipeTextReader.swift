import Foundation

/// Reads a recipe's text, fetching it from iCloud where it is not on the device.
struct RecipeTextReader: Sendable {
    /// What reading a recipe returns.
    struct Contents: Sendable {
        /// The recipe's text.
        let text: String

        /// When the contents read last changed, or `nil` where the file does not tell.
        let modificationDate: Date?
    }

    // How often, and how many times, an outdated copy on the device is checked for the newer one before it is read.
    private static let newestVersionCheckInterval: Duration = .milliseconds(200)
    private static let newestVersionChecks = 50

    private let fileStatus: @Sendable (URL) -> RecipeFileStatus?
    private let queue: OperationQueue
    private let recipeDirectory: RecipeDirectory
    private let sleep: @Sendable (Duration) async throws -> Void
    private let startDownloading: @Sendable (URL) throws -> Void

    /// Creates a reader, which reads one file at a time.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory the recipes sit in.
    ///   - qualityOfService: How urgent the reads are.
    ///   - fileStatus: What the file system reports of the file at a URL, or of the file iCloud promises there.
    ///   - startDownloading: Asks iCloud for a file's contents, returning before they arrive.
    ///   - sleep: Waits between two checks for the newer version of an outdated file.
    init(
        recipeDirectory: RecipeDirectory,
        qualityOfService: QualityOfService,
        fileStatus: @escaping @Sendable (URL) -> RecipeFileStatus? = RecipeFileStatus.read(at:),
        startDownloading: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        let readQueue = OperationQueue()
        readQueue.maxConcurrentOperationCount = 1
        readQueue.qualityOfService = qualityOfService

        self.fileStatus = fileStatus
        self.queue = readQueue
        self.recipeDirectory = recipeDirectory
        self.sleep = sleep
        self.startDownloading = startDownloading
    }

    /// Reads a recipe at its newest version.
    ///
    /// A recipe held only in iCloud, or whose newer version waits there, is fetched first, and the call returns once
    /// the text is on the device, so it takes as long as that fetch does. Where the fetch of a newer version does not
    /// land within seconds, the older version on the device is read. Cancelling the task gives up on the read.
    ///
    /// - Parameter fileName: The file's name inside the recipe directory, extension included.
    /// - Returns: The recipe's contents.
    /// - Throws: Whatever fetching or reading the file throws, or `CancellationError` when the task is cancelled.
    func read(fileName: String) async throws -> Contents {
        let url = recipeDirectory.url.appending(path: fileName)

        return try await recipeDirectory.url.withSecurityScope {
            let status = fileStatus(url)

            switch status?.downloadingStatus {
            case .current:
                break

            case .outdated, .notDownloaded, nil:
                if status?.isDownloading != true {
                    // The coordinated read reports a fetch that cannot start, and waits for one that can.
                    try? startDownloading(url)
                }

                // A coordinated read waits for missing contents, but returns an older version on the device at once.
                if status?.downloadingStatus == .outdated, status?.isDataless == false {
                    try await waitForNewestVersion(at: url)
                }
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

    private func waitForNewestVersion(at url: URL) async throws {
        var checks = 0

        while checks < Self.newestVersionChecks, fileStatus(url)?.downloadingStatus == .outdated {
            try await sleep(Self.newestVersionCheckInterval)
            checks += 1
        }
    }
}
