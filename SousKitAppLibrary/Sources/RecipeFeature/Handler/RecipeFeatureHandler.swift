import SousKit

/// What ``RecipeFeature`` reports to.
public protocol RecipeFeatureHandler {
    /// A cook chose to cook the recipe on screen.
    ///
    /// - Parameter recipe: The recipe to cook, as it was read.
    @MainActor
    func recipeFeatureDidStartCooking(recipe: Recipe)
}
