import Foundation
import RecipeLibrary

extension RecipeEntry {
    /// The file's name inside the recipe directory, extension included.
    var fileName: String {
        id
    }

    /// Creates an entry for a file sitting directly in the recipe directory, named after the file.
    ///
    /// - Parameters:
    ///   - fileName: The file's name inside the directory, extension included.
    ///   - availability: Whether the file's contents are on the device.
    ///   - summary: What is known of the file's contents, or `nil` where they have not been read.
    init(
        fileName: String,
        availability: RecipeAvailability,
        summary: RecipeSummary? = nil
    ) {
        self.init(
            id: fileName,
            name: Self.name(forFileNamed: fileName),
            availability: availability,
            summary: summary
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
