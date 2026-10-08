import RecipeLibrary

/// What ``KitchenFeature`` reports out of the kitchen to.
public protocol KitchenFeatureHandler {
    /// Another folder was picked to read recipes from, and it is recorded.
    ///
    /// - Parameter recipeRepository: The repository reading the folder.
    @MainActor
    func kitchenFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository)

    /// Another kind of recipe repository was picked to read from.
    ///
    /// - Parameter recipeRepositoryKind: The kind picked.
    @MainActor
    func kitchenFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind)

    /// A reset of the app was confirmed, and what the app remembers is to go.
    @MainActor
    func kitchenFeatureDidConfirmReset()
}
