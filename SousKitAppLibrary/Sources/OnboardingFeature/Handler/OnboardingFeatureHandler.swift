import RecipeLibrary

/// What ``OnboardingFeature`` reports its result to.
public protocol OnboardingFeatureHandler {
    /// The user picked a directory, and it is recorded.
    ///
    /// - Parameter recipeRepository: The repository reading the directory.
    @MainActor
    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository)

    /// Another kind of recipe repository was picked to read from, in place of the folder.
    ///
    /// - Parameter recipeRepositoryKind: The kind picked.
    @MainActor
    func onboardingFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind)
}
