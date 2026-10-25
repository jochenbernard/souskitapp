import RecipeLibrary

extension RecipeFeatureViewModel {
    /// The recipe's title as its screen names it: the one its header gives once read, or its listed one before.
    var title: String {
        guard case .recipe(let recipe) = recipeContent else {
            return recipeEntry.title
        }

        return recipeEntry.title(of: recipe.scaled)
    }
}
