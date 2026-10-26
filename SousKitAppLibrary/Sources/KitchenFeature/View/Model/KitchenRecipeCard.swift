import DesignSystem
import RecipeLibrary

/// One recipe as a card in the kitchen's grid.
struct KitchenRecipeCard: Identifiable, Hashable {
    /// The recipe the card opens.
    let recipeEntry: RecipeEntry

    /// The color standing in for a picture of the recipe, the same on every launch.
    let placeholderColor: SousPlaceholderColor

    /// Whether the picture the recipe's header names is known, which it is not before any recipe listed is read.
    let isPictureKnown: Bool

    var id: String {
        recipeEntry.id
    }

    /// Creates the card a recipe is listed as.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe.
    ///   - isPictureKnown: Whether the picture the recipe's header names is known.
    init(recipeEntry: RecipeEntry, isPictureKnown: Bool = true) {
        self.recipeEntry = recipeEntry
        self.placeholderColor = PlaceholderColorPick.color(forTitle: recipeEntry.title)
        self.isPictureKnown = isPictureKnown
    }
}
