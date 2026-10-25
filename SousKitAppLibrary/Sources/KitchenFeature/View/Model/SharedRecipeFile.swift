import Foundation
import RecipeLibrary

/// A recipe's file, copied out of the repository for the share sheet, which opens over the recipe's card.
struct SharedRecipeFile {
    /// The recipe whose card the sheet opens over.
    let recipeEntry: RecipeEntry

    /// Where the copy sits.
    let url: URL
}
