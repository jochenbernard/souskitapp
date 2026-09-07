import Observation
import RecipeLibrary

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeDirectory: RecipeDirectory
    var recipeList: KitchenRecipeList = .reading
    var recipePath: [RecipeFile] = []
    var openRecipe: OpenRecipe?

    nonisolated init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }
}
