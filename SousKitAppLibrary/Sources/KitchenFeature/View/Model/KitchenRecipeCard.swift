import DesignSystem
import RecipeLibrary

/// One recipe as a card in the kitchen's grid.
struct KitchenRecipeCard: Identifiable, Hashable {
    /// The recipe the card opens.
    let recipeEntry: RecipeEntry

    /// How long the recipe takes, or `nil` where its header does not say.
    let totalTime: TotalTime?

    /// The symbol standing in for a picture of the recipe.
    let placeholderSymbol: String

    /// The color standing in for a picture of the recipe, the same on every launch.
    let placeholderColor: SousPlaceholderColor

    var id: String {
        recipeEntry.id
    }
}
