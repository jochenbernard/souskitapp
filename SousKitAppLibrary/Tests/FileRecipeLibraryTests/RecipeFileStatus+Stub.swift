@testable import FileRecipeLibrary
import Foundation

extension RecipeFileStatus {
    /// A file with an older version on the device and a newer one in iCloud.
    ///
    /// - Parameters:
    ///   - date: When the older version last changed.
    ///   - isDataless: Whether the contents are missing from the device.
    ///   - isDownloading: Whether iCloud is fetching the newer version.
    /// - Returns: The status.
    static func outdated(
        modifiedAt date: Date,
        isDataless: Bool = true,
        isDownloading: Bool = false
    ) -> Self {
        Self(
            downloadingStatus: .outdated,
            modificationDate: date,
            isDownloading: isDownloading,
            isDataless: isDataless
        )
    }

    /// A file with no version on the device.
    ///
    /// - Parameter date: When the version in iCloud last changed.
    /// - Returns: The status.
    static func notDownloaded(modifiedAt date: Date) -> Self {
        Self(
            downloadingStatus: .notDownloaded,
            modificationDate: date,
            isDataless: true
        )
    }

    /// A file with its newest version on the device.
    ///
    /// - Parameter date: When the version last changed.
    /// - Returns: The status.
    static func current(modifiedAt date: Date?) -> Self {
        Self(downloadingStatus: .current, modificationDate: date)
    }
}
