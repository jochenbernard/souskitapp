import Foundation
import RecipeLibrary

/// One recipe ``MockRecipeRepository`` lists: a file kept in the app, and where it starts out.
struct MockRecipe: Sendable {
    /// The file's name without its extension, which no two recipes share.
    let id: String

    /// Whether the recipe is on the device before anything reads it.
    let availability: RecipeAvailability

    /// Whether fetching the recipe from iCloud fails, as it does with the iCloud servers out of reach.
    let isUnreachable: Bool

    /// The recipe's name, as a list shows it: the words of the file's name.
    var name: String {
        id.replacing("-", with: " ")
    }

    init(
        id: String,
        availability: RecipeAvailability = .downloaded,
        isUnreachable: Bool = false
    ) {
        self.id = id
        self.availability = availability
        self.isUnreachable = isUnreachable
    }

    /// Reads the recipe's file.
    ///
    /// - Returns: The recipe's text.
    /// - Throws: Whatever reading the file throws.
    func text() throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: id,
                withExtension: "sous",
                subdirectory: "Recipes"
            )
        else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return try String(contentsOf: url, encoding: .utf8)
    }
}
