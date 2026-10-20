import Foundation
import RecipeLibrary

/// Reads the recipes in a directory and in every directory inside it, leaving hidden ones, packages and what they hold
/// alone.
struct RecipeDirectoryReader: Sendable {
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isPackageKey
    ]

    private static let placeholderExtension = "icloud"
    private static let recipeExtension = "sous"

    private let fileStatus: @Sendable (URL) -> RecipeFileStatus?
    private let recipeDirectory: RecipeDirectory

    /// Creates a reader.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory recipes are read from.
    ///   - fileStatus: What the file system reports of the file at a URL, or of the file iCloud promises there.
    init(
        recipeDirectory: RecipeDirectory,
        fileStatus: @escaping @Sendable (URL) -> RecipeFileStatus? = RecipeFileStatus.read(at:)
    ) {
        self.recipeDirectory = recipeDirectory
        self.fileStatus = fileStatus
    }

    /// Reads the directory, down to the deepest directory inside it.
    ///
    /// It downloads nothing: a recipe held only in iCloud is listed as ``RecipeAvailability/notDownloaded``, and one
    /// whose newer version waits in iCloud as outdated and ``RecipeAvailability/downloading``, since it is fetched
    /// once listed. A directory inside that cannot be read is left out.
    ///
    /// - Returns: What the directory holds.
    /// - Throws: Whatever reading the directory itself throws.
    func readListing() throws -> RecipeDirectoryListing {
        let url = recipeDirectory.url

        return try url.withSecurityScope {
            try NSFileCoordinator.coordinateReading(at: url) { coordinatedURL in
                var listing = RecipeDirectoryListing(recipeFiles: [], directoryPaths: [])
                try read(
                    directoryAt: coordinatedURL,
                    path: "",
                    into: &listing
                )
                listing.recipeFiles.sort(by: { $0.path.localizedStandardCompare($1.path) == .orderedAscending })

                return listing
            }
        }
    }

    /// Adds what a directory holds to a listing, then what each directory inside it holds.
    ///
    /// - Parameters:
    ///   - directory: The directory.
    ///   - path: Where the directory sits inside the recipe directory, empty for the recipe directory itself.
    ///   - listing: The listing to add to.
    private func read(
        directoryAt directory: URL,
        path: String,
        into listing: inout RecipeDirectoryListing
    ) throws {
        let entries = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(Self.resourceKeys),
            options: []
        )

        listing.directoryPaths.insert(path)

        var recipeFiles: [RecipeFile] = []
        var placeholders: [RecipeFile] = []

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = Self.recipeFileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)
                placeholders.append(placeholderFile(at: Self.joined(path, name), url: url))
            } else if !entryName.hasPrefix(".") {
                // A package is one document in Files, so nothing inside it is listed.
                guard
                    let values = try? entry.resourceValues(forKeys: Self.resourceKeys),
                    values.isPackage != true
                else {
                    continue
                }

                if values.isDirectory == true {
                    try? read(
                        directoryAt: entry,
                        path: Self.joined(path, entryName),
                        into: &listing
                    )
                } else if Self.isRecipeFileName(entryName), let status = fileStatus(entry) {
                    // A file iCloud evicted in place keeps the dates of the contents it stands in for.
                    recipeFiles.append(
                        RecipeFile(
                            path: Self.joined(path, entryName),
                            availability: Self.availability(of: status),
                            modificationDate: status.modificationDate,
                            isOutdated: status.downloadingStatus == .outdated
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
    private func placeholderFile(at path: String, url: URL) -> RecipeFile {
        let status = fileStatus(url)

        return RecipeFile(
            path: path,
            availability: status?.isDownloading == true ? .downloading : .notDownloaded,
            modificationDate: status?.modificationDate
        )
    }

    private static func availability(of status: RecipeFileStatus) -> RecipeAvailability {
        switch status.downloadingStatus {
        case .current:
            .downloaded

        case .outdated:
            .downloading

        case .notDownloaded:
            status.isDownloading ? .downloading : .notDownloaded
        }
    }
}
