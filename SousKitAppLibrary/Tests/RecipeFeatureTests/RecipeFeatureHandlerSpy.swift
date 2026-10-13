@testable import RecipeFeature
import SousKit

/// Records what the recipe feature reports, with cooking open over it where a test says so.
final class RecipeFeatureHandlerSpy: RecipeFeatureHandler {
    var recipeFeatureIsCooking = false

    private(set) var cookedRecipes: [Recipe] = []
    private(set) var resumedRecipes: [Recipe] = []
    private(set) var restorations: [RecipeFeatureRestoration] = []

    func recipeFeatureDidStartCooking(recipe: Recipe) {
        cookedRecipes.append(recipe)
    }

    func recipeFeatureDidResumeCooking(recipe: Recipe) {
        resumedRecipes.append(recipe)
    }

    func recipeFeatureDidChangeRestoration(_ restoration: RecipeFeatureRestoration) {
        restorations.append(restoration)
    }
}
