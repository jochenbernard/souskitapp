import DesignSystem
import RecipeLibrary

/// One recipe as a card in the kitchen's grid.
struct KitchenRecipeCard: Identifiable, Hashable {
    /// The recipe the card opens.
    let recipeEntry: RecipeEntry

    /// The color standing in for a picture of the recipe, the same on every launch.
    let placeholderColor: SousPlaceholderColor

    var id: String {
        recipeEntry.id
    }

    /// Creates the card a recipe is listed as.
    ///
    /// - Parameter recipeEntry: The recipe.
    init(recipeEntry: RecipeEntry) {
        self.recipeEntry = recipeEntry
        self.placeholderColor = PlaceholderColorPick.color(forTitle: recipeEntry.title)
    }
}
