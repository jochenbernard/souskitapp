import Darwin
import Foundation

/// What the file system reports of a recipe file's contents, as far as listing and reading it go.
struct RecipeFileStatus: Sendable, Hashable {
    /// Which version of the contents the device holds.
    enum DownloadingStatus: Sendable, Hashable {
        /// The newest, or the file is not in iCloud.
        case current

        /// An older one, with a newer one in iCloud, whatever the file's date says.
        case outdated

        /// None.
        case notDownloaded
    }

    private static let resourceKeys: Set<URLResourceKey> = [
        .contentModificationDateKey,
        .isUbiquitousItemKey,
        .ubiquitousItemDownloadingStatusKey,
        .ubiquitousItemIsDownloadingKey
    ]

    /// Which version of the contents the device holds.
    let downloadingStatus: DownloadingStatus

    /// When the contents last changed, or `nil` where the file does not tell.
    let modificationDate: Date?

    /// Whether iCloud is fetching the contents.
    let isDownloading: Bool

    /// Whether the contents are missing from the device, so a read has to wait for them.
    let isDataless: Bool

    /// Creates a status.
    ///
    /// - Parameters:
    ///   - downloadingStatus: Which version of the contents the device holds.
    ///   - modificationDate: When the contents last changed.
    ///   - isDownloading: Whether iCloud is fetching the contents.
    ///   - isDataless: Whether the contents are missing from the device.
    init(
        downloadingStatus: DownloadingStatus,
        modificationDate: Date?,
        isDownloading: Bool = false,
        isDataless: Bool = false
    ) {
        self.downloadingStatus = downloadingStatus
        self.modificationDate = modificationDate
        self.isDownloading = isDownloading
        self.isDataless = isDataless
    }

    /// Reads the status of the file at a URL, or of the file iCloud promises there, as it is now.
    ///
    /// - Parameter url: The file.
    /// - Returns: The status, or `nil` where neither the file nor iCloud tells.
    static func read(at url: URL) -> Self? {
        var url = url
        // A URL keeps the values read through it, and a status read again has to see what changed since.
        url.removeAllCachedResourceValues()

        // An evicted file's placeholder stands where the file would be, which only the promised values describe.
        guard
            let values = (try? url.resourceValues(forKeys: resourceKeys))
                ?? (try? url.promisedItemResourceValues(forKeys: resourceKeys))
        else {
            return nil
        }

        return Self(
            downloadingStatus: downloadingStatus(of: values),
            modificationDate: values.contentModificationDate,
            isDownloading: values.ubiquitousItemIsDownloading == true,
            isDataless: isDataless(at: url)
        )
    }

    private static func downloadingStatus(of values: URLResourceValues) -> DownloadingStatus {
        guard values.isUbiquitousItem == true else {
            return .current
        }

        switch values.ubiquitousItemDownloadingStatus {
        case URLUbiquitousItemDownloadingStatus.downloaded:
            return .outdated

        case URLUbiquitousItemDownloadingStatus.notDownloaded:
            return .notDownloaded

        default:
            return .current
        }
    }

    private static func isDataless(at url: URL) -> Bool {
        var info = stat()

        guard lstat(url.path(percentEncoded: false), &info) == 0 else {
            return true
        }

        return info.st_flags & UInt32(SF_DATALESS) != 0
    }
}
