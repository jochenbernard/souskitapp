import Foundation

/// Reads the recipes sitting directly in a directory, leaving the directories inside it alone.
public struct RecipeDirectoryReader: Sendable {
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isUbiquitousItemKey,
        .ubiquitousItemDownloadingStatusKey,
        .ubiquitousItemIsDownloadingKey
    ]

    private static let placeholderExtension = "icloud"

    private let recipeDirectory: RecipeDirectory

    /// Creates a reader.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from.
    public init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }

    /// Reads the directory's top level.
    ///
    /// It downloads nothing: a recipe held only in iCloud is listed as
    /// ``RecipeFileAvailability/notDownloaded``.
    ///
    /// - Returns: The recipes found, ordered by name.
    /// - Throws: Whatever reading the directory throws.
    public func readRecipeFiles() throws -> [RecipeFile] {
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
                placeholders.append(
                    RecipeFile(url: url, availability: availabilityOfPlaceholder(at: url))
                )
            } else if isRecipeFileName(entryName) {
                guard
                    let values = try? entry.resourceValues(forKeys: resourceKeys),
                    values.isDirectory == false
                else {
                    continue
                }

                recipeFiles.append(RecipeFile(url: entry, availability: availability(of: values)))
            }
        }

        let listed = Set(recipeFiles.map(\.fileName))
        recipeFiles.append(contentsOf: placeholders.filter({ !listed.contains($0.fileName) }))

        return recipeFiles.sorted(by: isOrderedBefore)
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
        !entryName.hasPrefix(".") && entryName.lowercased().hasSuffix(".\(RecipeFile.pathExtension)")
    }

    /// What a placeholder reports about the recipe it stands in for.
    ///
    /// A placeholder stays in the directory while the fetch it triggered runs, so a recipe on its
    /// way down is reported as ``RecipeFileAvailability/downloading`` rather than as absent.
    private static func availabilityOfPlaceholder(at url: URL) -> RecipeFileAvailability {
        guard
            let values = try? url.resourceValues(forKeys: resourceKeys),
            values.ubiquitousItemIsDownloading == true
        else {
            return .notDownloaded
        }

        return .downloading
    }

    private static func availability(of values: URLResourceValues) -> RecipeFileAvailability {
        guard
            values.isUbiquitousItem == true,
            values.ubiquitousItemDownloadingStatus == .notDownloaded
        else {
            return .downloaded
        }

        return values.ubiquitousItemIsDownloading == true ? .downloading : .notDownloaded
    }

    /// Whether one recipe sorts before another, by name and then by file name.
    private static func isOrderedBefore(_ lhs: RecipeFile, _ rhs: RecipeFile) -> Bool {
        switch lhs.name.localizedStandardCompare(rhs.name) {
        case .orderedAscending:
            true

        case .orderedDescending:
            false

        case .orderedSame:
            lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
        }
    }
}
