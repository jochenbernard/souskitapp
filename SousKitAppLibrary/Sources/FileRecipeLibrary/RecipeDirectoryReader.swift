import Foundation
import RecipeLibrary

/// Reads the recipes sitting directly in a directory, leaving the directories inside it alone.
struct RecipeDirectoryReader: Sendable {
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

    /// Reads the directory's top level.
    ///
    /// It downloads nothing: a recipe held only in iCloud is listed as ``RecipeAvailability/notDownloaded``, and one
    /// whose newer version waits in iCloud as outdated and ``RecipeAvailability/downloading``, since it is fetched
    /// once listed.
    ///
    /// - Returns: The recipe files found, ordered by path.
    /// - Throws: Whatever reading the directory throws.
    func readRecipeFiles() throws -> [RecipeFile] {
        let url = recipeDirectory.url

        return try url.withSecurityScope {
            try NSFileCoordinator.coordinateReading(at: url, recipeFiles(inDirectoryAt:))
        }
    }

    private func recipeFiles(inDirectoryAt directory: URL) throws -> [RecipeFile] {
        let entries = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )

        var recipeFiles: [RecipeFile] = []
        var placeholders: [RecipeFile] = []

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = Self.recipeFileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)
                placeholders.append(placeholderFile(named: name, at: url))
            } else if Self.isRecipeFileName(entryName) {
                guard
                    let values = try? entry.resourceValues(forKeys: [.isDirectoryKey]),
                    values.isDirectory == false,
                    let status = fileStatus(entry)
                else {
                    continue
                }

                // A file iCloud evicted in place keeps the dates of the contents it stands in for.
                recipeFiles.append(
                    RecipeFile(
                        path: entryName,
                        availability: Self.availability(of: status),
                        modificationDate: status.modificationDate,
                        isOutdated: status.downloadingStatus == .outdated
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
    private func placeholderFile(named name: String, at url: URL) -> RecipeFile {
        let status = fileStatus(url)

        return RecipeFile(
            path: name,
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
