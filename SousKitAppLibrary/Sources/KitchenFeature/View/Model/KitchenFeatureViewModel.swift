import Observation
import RecipeLibrary

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeDirectory: RecipeDirectory
    var recipeList: KitchenRecipeList = .reading

    nonisolated init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }
}
