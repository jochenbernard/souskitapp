@testable import RecipeFeature
import SousKit

/// Records what the recipe feature reports.
final class RecipeFeatureHandlerSpy: RecipeFeatureHandler {
    private(set) var cookedRecipes: [Recipe] = []

    func recipeFeatureDidStartCooking(recipe: Recipe) {
        cookedRecipes.append(recipe)
    }
}
