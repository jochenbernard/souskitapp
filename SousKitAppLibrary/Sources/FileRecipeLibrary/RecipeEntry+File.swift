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
    init(
        path: String,
        availability: RecipeAvailability,
        summary: RecipeSummary? = nil
    ) {
        let components = path.split(separator: "/").map(String.init)

        self.init(
            id: path,
            name: Self.name(forFileNamed: components.last ?? path),
            availability: availability,
            summary: summary,
            folderPath: Array(components.dropLast())
        )
    }

    private static func name(forFileNamed fileName: String) -> String {
        let stem = URL(filePath: fileName).deletingPathExtension().lastPathComponent
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
