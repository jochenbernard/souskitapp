import Foundation
import RecipeLibrary

extension RecipeEntry {
    /// Where the file sits inside the recipe directory, extension included.
    var path: String {
        id
    }

    /// Creates an entry for a file inside the recipe directory, named after the file and found by where it sits, so
    /// files sharing a name in different directories are different recipes.
    ///
    /// - Parameters:
    ///   - path: Where the file sits inside the directory, extension included.
    ///   - availability: Whether the file's contents are on the device.
    ///   - summary: What is known of the file's contents, or `nil` where they have not been read.
    ///   - pictures: The pictures in the directory, by where each sits inside it, among which the one the summary
    ///     names is looked for.
    init(
        path: String,
        availability: RecipeAvailability,
        summary: RecipeSummary? = nil,
        pictures: [String: RecipePicture] = [:]
    ) {
        let folderPath = path.split(separator: "/").dropLast().map(String.init)

        self.init(
            id: path,
            name: Self.name(forFileAt: path),
            availability: availability,
            summary: summary,
            folderPath: folderPath,
            picture: summary?.imagePath(inFolder: folderPath).flatMap({ pictures[$0] })
        )
    }

    /// The name of the recipe in a file, from the file's name without its extension, with its words spaced.
    ///
    /// - Parameter path: Where the file sits, extension included.
    /// - Returns: The name.
    static func name(forFileAt path: String) -> String {
        let stem = URL(filePath: path).deletingPathExtension().lastPathComponent
        let words = stem.split(whereSeparator: isSeparator)

        guard !words.isEmpty else {
            return stem
        }

        return words.joined(separator: " ")
    }

    private static func isSeparator(_ character: Character) -> Bool {
        character == "-" || character == "_" || character.isWhitespace
    }
}
