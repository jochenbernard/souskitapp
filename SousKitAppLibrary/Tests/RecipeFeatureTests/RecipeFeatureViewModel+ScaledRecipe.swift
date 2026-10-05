@testable import RecipeFeature
import Testing

extension RecipeFeatureViewModel {
    /// The recipe on screen, recording an issue where none reached it.
    var scaledRecipe: ScaledRecipe? {
        guard case .recipe(let recipe) = recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return nil
        }

        return recipe
    }
}
