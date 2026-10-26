import Foundation

/// A recipe's file, copied out of the repository for the share sheet, which opens over the recipe's card.
struct SharedRecipeFile {
    /// The id of the recipe whose card the sheet opens over.
    let recipeID: String

    /// Where the copy sits.
    let url: URL
}
