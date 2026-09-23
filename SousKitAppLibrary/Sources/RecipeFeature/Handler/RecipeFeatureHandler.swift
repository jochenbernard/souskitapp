import SousKit

/// What ``RecipeFeature`` reports to.
public protocol RecipeFeatureHandler {
    /// A cook chose to cook the recipe on screen.
    ///
    /// - Parameter recipe: The recipe to cook, at the scale it is on screen at.
    @MainActor
    func recipeFeatureDidStartCooking(recipe: Recipe)
}
