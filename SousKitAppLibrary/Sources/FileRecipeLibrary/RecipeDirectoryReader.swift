import Foundation
import RecipeLibrary

/// Reads the recipes in a directory and in every directory inside it, leaving hidden ones and what they hold alone.
struct RecipeDirectoryReader: Sendable {
    private static let resourceKeys: Set<URLResourceKey> = [
        .contentModificationDateKey,
        .isDirectoryKey,
        .isUbiquitousItemKey,
        .ubiquitousItemDownloadingStatusKey,
        .ubiquitousItemIsDownloadingKey
    ]

    private static let placeholderExtension = "icloud"
    private static let recipeExtension = "sous"

    private let recipeDirectory: RecipeDirectory

    /// Creates a reader.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from.
    init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }

    /// Reads the directory, down to the deepest directory inside it.
    ///
    /// It downloads nothing: a recipe held only in iCloud is listed as ``RecipeAvailability/notDownloaded``. A
    /// directory inside that cannot be read is left out.
    ///
    /// - Returns: What the directory holds.
    /// - Throws: Whatever reading the directory itself throws.
    func readListing() throws -> RecipeDirectoryListing {
        let url = recipeDirectory.url

        return try url.withSecurityScope {
            try NSFileCoordinator.coordinateReading(at: url) { coordinatedURL in
                var listing = RecipeDirectoryListing(recipeFiles: [], directoryPaths: [])
                try Self.read(directoryAt: coordinatedURL, path: "", into: &listing)

                return RecipeDirectoryListing(
                    recipeFiles: listing.recipeFiles.sorted(by: { Self.isOrderedBefore($0.path, $1.path) }),
                    directoryPaths: listing.directoryPaths.sorted(by: Self.isOrderedBefore)
                )
            }
        }
    }

    /// Adds what a directory holds to a listing, then what each directory inside it holds.
    ///
    /// - Parameters:
    ///   - directory: The directory.
    ///   - path: Where the directory sits inside the recipe directory, empty for the recipe directory itself.
    ///   - listing: The listing to add to.
    private static func read(
        directoryAt directory: URL,
        path: String,
        into listing: inout RecipeDirectoryListing
    ) throws {
        let entries = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        )

        listing.directoryPaths.append(path)

        var recipeFiles: [RecipeFile] = []
        var placeholders: [RecipeFile] = []

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = recipeFileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)
                placeholders.append(placeholderFile(at: joined(path, name), url: url))
            } else if !entryName.hasPrefix(".") {
                guard let values = try? entry.resourceValues(forKeys: resourceKeys) else {
                    continue
                }

                if values.isDirectory == true {
                    try? read(directoryAt: entry, path: joined(path, entryName), into: &listing)
                } else if isRecipeFileName(entryName) {
                    // A file iCloud evicted in place keeps the dates of the contents it stands in for.
                    recipeFiles.append(
                        RecipeFile(
                            path: joined(path, entryName),
                            availability: availability(of: values),
                            modificationDate: values.contentModificationDate
                        )
                    )
                }
            }
        }

        let listed = Set(recipeFiles.map(\.path))
        listing.recipeFiles.append(contentsOf: recipeFiles)
        listing.recipeFiles.append(contentsOf: placeholders.filter({ !listed.contains($0.path) }))
    }

    /// The path of an entry inside the directory at `path`.
    private static func joined(_ path: String, _ entryName: String) -> String {
        path.isEmpty ? entryName : "\(path)/\(entryName)"
    }

    private static func isOrderedBefore(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

    /// The recipe an iCloud placeholder entry stands in for, or `nil` where it stands in for none.
    ///
    /// iCloud names the placeholder for an evicted `Crepes.sous` `.Crepes.sous.icloud`. Listing
    /// the directory with `skipsHiddenFiles` would drop that entry, and the recipe with it.
    private static func recipeFileName(forPlaceholderNamed entryName: String) -> String? {
        let suffix = ".\(placeholderExtension)"

        guard entryName.hasPrefix("."), entryName.lowercased().hasSuffix(suffix) else {
            return nil
        }

        let name = String(entryName.dropFirst().dropLast(suffix.count))

        return isRecipeFileName(name) ? name : nil
    }

    private static func isRecipeFileName(_ entryName: String) -> Bool {
        !entryName.hasPrefix(".") && entryName.lowercased().hasSuffix(".\(recipeExtension)")
    }

    /// What a placeholder reports about the recipe it stands in for.
    ///
    /// A placeholder stays in the directory while the fetch it triggered runs, so a recipe on its
    /// way down is reported as ``RecipeAvailability/downloading`` rather than as absent. The
    /// recipe's own URL is asked, not the placeholder's: the placeholder's dates are its own.
    private static func placeholderFile(at path: String, url: URL) -> RecipeFile {
        let values = try? url.resourceValues(forKeys: resourceKeys)

        return RecipeFile(
            path: path,
            availability: values?.ubiquitousItemIsDownloading == true ? .downloading : .notDownloaded,
            modificationDate: values?.contentModificationDate
        )
    }

    private static func availability(of values: URLResourceValues) -> RecipeAvailability {
        guard
            values.isUbiquitousItem == true,
            values.ubiquitousItemDownloadingStatus == .notDownloaded
        else {
            return .downloaded
        }

        return values.ubiquitousItemIsDownloading == true ? .downloading : .notDownloaded
    }
}
