import Foundation
import RecipeLibrary

/// Reads the recipes sitting directly in a directory, leaving the directories inside it alone.
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

    /// Reads the directory's top level.
    ///
    /// It downloads nothing: a recipe held only in iCloud is listed as
    /// ``RecipeAvailability/notDownloaded``.
    ///
    /// - Returns: The recipe files found, ordered by path.
    /// - Throws: Whatever reading the directory throws.
    func readRecipeFiles() throws -> [RecipeFile] {
        let url = recipeDirectory.url

        return try url.withSecurityScope {
            try NSFileCoordinator.coordinateReading(at: url, Self.recipeFiles(inDirectoryAt:))
        }
    }

    private static func recipeFiles(inDirectoryAt directory: URL) throws -> [RecipeFile] {
        let entries = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        )

        var recipeFiles: [RecipeFile] = []
        var placeholders: [RecipeFile] = []

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = recipeFileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)
                placeholders.append(placeholderFile(named: name, at: url))
            } else if isRecipeFileName(entryName) {
                guard
                    let values = try? entry.resourceValues(forKeys: resourceKeys),
                    values.isDirectory == false
                else {
                    continue
                }

                // A file iCloud evicted in place keeps the dates of the contents it stands in for.
                recipeFiles.append(
                    RecipeFile(
                        path: entryName,
                        availability: availability(of: values),
                        modificationDate: values.contentModificationDate
                    )
                )
            }
        }

        let listed = Set(recipeFiles.map(\.path))
        recipeFiles.append(contentsOf: placeholders.filter({ !listed.contains($0.path) }))

        return recipeFiles.sorted(by: { $0.path.localizedStandardCompare($1.path) == .orderedAscending })
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
    private static func placeholderFile(named name: String, at url: URL) -> RecipeFile {
        let values = try? url.resourceValues(forKeys: resourceKeys)

        return RecipeFile(
            path: name,
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
