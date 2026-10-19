import Foundation
import RecipeLibrary
import UniformTypeIdentifiers

/// Reads the recipes in a directory and in every directory inside it, and the pictures their headers can name, leaving
/// hidden ones, packages and what they hold alone.
struct RecipeDirectoryReader: Sendable {
    /// The files one directory holds, the placeholders iCloud left beside them apart.
    private struct DirectoryFiles {
        var recipes: [RecipeFile] = []
        var recipePlaceholders: [RecipeFile] = []
        var pictures: [RecipeFile] = []
        var picturePlaceholders: [RecipeFile] = []

        /// Adds the files to a listing, each placeholder only where the file it stands in for is not listed itself.
        func add(to listing: inout RecipeDirectoryListing) {
            let recipePaths = Set(recipes.map(\.path))
            listing.recipeFiles.append(contentsOf: recipes)
            listing.recipeFiles.append(contentsOf: recipePlaceholders.filter({ !recipePaths.contains($0.path) }))

            let picturePaths = Set(pictures.map(\.path))

            for file in pictures + picturePlaceholders.filter({ !picturePaths.contains($0.path) }) {
                listing.pictures[file.path] = RecipePicture(
                    id: file.path,
                    modificationDate: file.modificationDate,
                    availability: file.availability
                )
            }
        }
    }

    private static let resourceKeys: Set<URLResourceKey> = [
        .contentModificationDateKey,
        .isDirectoryKey,
        .isPackageKey,
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
                try Self.read(
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

        listing.directoryPaths.insert(path)

        var files = DirectoryFiles()

        for entry in entries {
            let entryName = entry.lastPathComponent

            if let name = fileName(forPlaceholderNamed: entryName) {
                // Built off the entry, not off `directory`: listing resolves the symlinks in
                // front of a directory, and a URL built the other way matches no entry.
                let url = entry.deletingLastPathComponent().appending(path: name)

                if isRecipeFileName(name) {
                    files.recipePlaceholders.append(placeholderFile(at: joined(path, name), url: url))
                } else if isPictureFileName(name) {
                    files.picturePlaceholders.append(placeholderFile(at: joined(path, name), url: url))
                }
            } else if !entryName.hasPrefix(".") {
                // A package is one document in Files, so nothing inside it is listed.
                guard
                    let values = try? entry.resourceValues(forKeys: resourceKeys),
                    values.isPackage != true
                else {
                    continue
                }

                if values.isDirectory == true {
                    try? read(
                        directoryAt: entry,
                        path: joined(path, entryName),
                        into: &listing
                    )
                } else if isRecipeFileName(entryName) {
                    files.recipes.append(file(at: joined(path, entryName), values: values))
                } else if isPictureFileName(entryName) {
                    files.pictures.append(file(at: joined(path, entryName), values: values))
                }
            }
        }

        files.add(to: &listing)
    }

    /// The path of an entry inside the directory at `path`.
    private static func joined(_ path: String, _ entryName: String) -> String {
        path.isEmpty ? entryName : "\(path)/\(entryName)"
    }

    /// The file an iCloud placeholder entry stands in for, or `nil` where it stands in for none.
    ///
    /// iCloud names the placeholder for an evicted `Crepes.sous` `.Crepes.sous.icloud`. Listing
    /// the directory with `skipsHiddenFiles` would drop that entry, and the recipe with it.
    private static func fileName(forPlaceholderNamed entryName: String) -> String? {
        let suffix = ".\(placeholderExtension)"

        guard entryName.hasPrefix("."), entryName.lowercased().hasSuffix(suffix) else {
            return nil
        }

        let name = String(entryName.dropFirst().dropLast(suffix.count))

        return name.hasPrefix(".") ? nil : name
    }

    private static func isRecipeFileName(_ entryName: String) -> Bool {
        !entryName.hasPrefix(".") && entryName.lowercased().hasSuffix(".\(recipeExtension)")
    }

    private static func isPictureFileName(_ entryName: String) -> Bool {
        let fileExtension = URL(filePath: entryName).pathExtension

        return !fileExtension.isEmpty && UTType(filenameExtension: fileExtension)?.conforms(to: .image) == true
    }

    /// A file on the device or evicted in place, which keeps the dates of the contents it stands in for.
    private static func file(at path: String, values: URLResourceValues) -> RecipeFile {
        RecipeFile(
            path: path,
            availability: availability(of: values),
            modificationDate: values.contentModificationDate
        )
    }

    /// What a placeholder reports about the file it stands in for.
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
