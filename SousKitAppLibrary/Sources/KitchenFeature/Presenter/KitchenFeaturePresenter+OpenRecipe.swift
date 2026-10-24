import RecipeFeature
import RecipeLibrary

extension KitchenFeaturePresenter {
    /// Shows the recipe on the stack as it is listed now, such as with the picture a download brought.
    @MainActor
    func showOpenRecipe(in recipeEntries: [RecipeEntry]) {
        guard
            let openRecipe = viewModel.openRecipe,
            let recipeEntry = recipeEntries.first(where: { $0.id == openRecipe.recipeEntry.id })
        else {
            return
        }

        openRecipe.feature.show(recipeEntry)
    }
}
