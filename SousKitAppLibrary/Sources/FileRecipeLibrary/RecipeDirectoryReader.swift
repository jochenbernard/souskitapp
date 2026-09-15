import Foundation
import RecipeLibrary

/// Reads the recipes sitting directly in a directory, leaving the directories inside it alone.
struct RecipeDirectoryReader: Sendable {
    private static let resourceKeys: Set<URLResourceKey> = [
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
    /// - Returns: The recipes found, ordered by name.
    /// - Throws: Whatever reading the directory throws.
    func readRecipeEntries() throws -> [RecipeEntry] {
        let url = recipeDirectory.url

        return try url.withSecurityScope {
            try NSFileCoordinator.coordinateReading(at: url, Self.recipeEntries(inDirectoryAt:))
        }
    }

    private static func recipeEntries(inDirectoryAt directory: URL) throws -> [RecipeEntry] {
        let entries = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        )

        var recipeEntries: [RecipeEntry] = []
        var placeholders: [RecipeEntry] = []

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = recipeFileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)
                placeholders.append(
                    RecipeEntry(fileName: name, availability: availabilityOfPlaceholder(at: url))
                )
            } else if isRecipeFileName(entryName) {
                guard
                    let values = try? entry.resourceValues(forKeys: resourceKeys),
                    values.isDirectory == false
                else {
                    continue
                }

                recipeEntries.append(RecipeEntry(fileName: entryName, availability: availability(of: values)))
            }
        }

        let listed = Set(recipeEntries.map(\.fileName))
        recipeEntries.append(contentsOf: placeholders.filter({ !listed.contains($0.fileName) }))

        return recipeEntries.sorted(by: isOrderedBefore)
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
    /// way down is reported as ``RecipeAvailability/downloading`` rather than as absent.
    private static func availabilityOfPlaceholder(at url: URL) -> RecipeAvailability {
        guard
            let values = try? url.resourceValues(forKeys: resourceKeys),
            values.ubiquitousItemIsDownloading == true
        else {
            return .notDownloaded
        }

        return .downloading
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

    /// Whether one recipe sorts before another, by name and then by file name.
    private static func isOrderedBefore(_ lhs: RecipeEntry, _ rhs: RecipeEntry) -> Bool {
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
