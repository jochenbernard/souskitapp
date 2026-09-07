import RecipeLibrary

/// What ``OnboardingFeature`` reports its result to.
public protocol OnboardingFeatureHandler {
    /// The user picked a directory, and it is recorded.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from.
    @MainActor
    func onboardingFeatureDidFinish(recipeDirectory: RecipeDirectory)
}
