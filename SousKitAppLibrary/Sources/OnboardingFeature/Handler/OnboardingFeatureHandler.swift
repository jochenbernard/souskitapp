import RecipeLibrary

/// What ``OnboardingFeature`` reports its result to.
public protocol OnboardingFeatureHandler {
    /// The user picked a directory, and it is recorded.
    ///
    /// - Parameter recipeRepository: The repository reading the directory.
    @MainActor
    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository)

    /// The mock recipes were chosen in place of a folder, which a debug build offers where no folder can be picked,
    /// such as on a simulator.
    @MainActor
    func onboardingFeatureDidChooseMockRecipes()
}
