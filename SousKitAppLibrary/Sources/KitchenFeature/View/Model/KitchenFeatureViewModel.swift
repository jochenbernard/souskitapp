import Observation
import RecipeLibrary

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeDirectory: RecipeDirectory
    var recipeList: KitchenRecipeList = .reading
    var screenPath: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var openCooking: OpenCooking?

    nonisolated init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }
}
