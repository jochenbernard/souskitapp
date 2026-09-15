import RecipeLibrary

/// What ``OnboardingFeature`` reports its result to.
public protocol OnboardingFeatureHandler {
    /// The user picked a directory, and it is recorded.
    ///
    /// - Parameter recipeRepository: The repository reading the directory.
    @MainActor
    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository)
}
