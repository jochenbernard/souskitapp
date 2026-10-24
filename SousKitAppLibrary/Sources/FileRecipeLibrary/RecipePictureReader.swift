import Foundation
import RecipeLibrary

/// Reads the pictures recipes name, fetching them from iCloud where they are not on the device at their newest version.
struct RecipePictureReader: Sendable {
    // Two at a time: decoding a large photo takes a while, and one waiting holds up no other.
    private static let concurrentReadCount = 2
    // How often, and how many times, an outdated copy on the device is checked for the newer one before it is read.
    private static let newestVersionCheckInterval: Duration = .milliseconds(200)
    private static let newestVersionChecks = 50

    private let fileStatus: @Sendable (URL) -> RecipeFileStatus?
    private let queue: OperationQueue
    private let recipeDirectory: RecipeDirectory
    private let sleep: @Sendable (Duration) async throws -> Void
    private let startDownloading: @Sendable (URL) throws -> Void

    /// Creates a reader.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory the pictures sit in.
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
        readQueue.maxConcurrentOperationCount = Self.concurrentReadCount
        readQueue.qualityOfService = qualityOfService

        self.fileStatus = fileStatus
        self.queue = readQueue
        self.recipeDirectory = recipeDirectory
        self.sleep = sleep
        self.startDownloading = startDownloading
    }

    /// Fetches a picture from iCloud at its newest version, returning once it is on the device.
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

    /// Reads a picture at its newest version, fetching it first where it is not on the device or a newer version waits
    /// in iCloud.
    ///
    /// Where the fetch of a newer version does not land within seconds, the older version on the device is read.
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

            return try await CancellableFileCoordination.read(
                at: url,
                queue: queue,
                read
            )
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
