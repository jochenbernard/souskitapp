import SousKit

/// What ``RecipeFeature`` reports to.
public protocol RecipeFeatureHandler {
    /// A cook chose to cook the recipe on screen.
    ///
    /// - Parameter recipe: The recipe to cook, at the scale it is on screen at.
    @MainActor
    func recipeFeatureDidStartCooking(recipe: Recipe)

    /// The recipe was read on a screen restored to cooking from it, so cooking opens again as it was left.
    ///
    /// - Parameter recipe: The recipe to cook, at the scale it is on screen at.
    @MainActor
    func recipeFeatureDidResumeCooking(recipe: Recipe)

    /// How the screen stands changed, for a cold start to restore.
    ///
    /// - Parameter restoration: How the screen stands now.
    @MainActor
    func recipeFeatureDidChangeRestoration(_ restoration: RecipeFeatureRestoration)
}
