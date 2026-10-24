import Foundation
import RecipeLibrary

/// A recipe file, or a picture a recipe can name, as its directory lists it, before anything reads it.
struct RecipeFile: Sendable, Hashable {
    /// Where the file sits inside the recipe directory, extension included.
    let path: String

    /// Whether the file's contents are on the device.
    let availability: RecipeAvailability

    /// When the file's contents last changed, or `nil` where iCloud does not tell.
    let modificationDate: Date?

    /// Whether a newer version of the contents waits in iCloud, whatever `modificationDate` says.
    let isOutdated: Bool

    /// Creates a file.
    ///
    /// - Parameters:
    ///   - path: Where the file sits inside the recipe directory, extension included.
    ///   - availability: Whether the file's contents are on the device.
    ///   - modificationDate: When the file's contents last changed.
    ///   - isOutdated: Whether a newer version of the contents waits in iCloud.
    init(
        path: String,
        availability: RecipeAvailability,
        modificationDate: Date?,
        isOutdated: Bool = false
    ) {
        self.path = path
        self.availability = availability
        self.modificationDate = modificationDate
        self.isOutdated = isOutdated
    }

    /// The entry listing the file.
    ///
    /// - Parameters:
    ///   - summary: What is known of the file's contents, or `nil` where they have not been read.
    ///   - pictures: The pictures in the directory, by where each sits inside it.
    /// - Returns: The entry.
    func recipeEntry(summary: RecipeSummary?, pictures: [String: RecipePicture]) -> RecipeEntry {
        RecipeEntry(
            path: path,
            availability: availability,
            summary: summary,
            pictures: pictures
        )
    }
}
