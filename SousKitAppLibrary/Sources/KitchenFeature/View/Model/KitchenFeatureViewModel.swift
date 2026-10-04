import Observation
import RecipeLibrary

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeRepositoryName: String
    let recipeRepositoryKind: RecipeRepositoryKind
    var recipeList: KitchenRecipeList = .reading
    var isRestoring = false
    var screenPath: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var openCooking: OpenCooking?
    var isConfirmingReset = false

    nonisolated init(
        recipeRepositoryName: String,
        recipeRepositoryKind: RecipeRepositoryKind
    ) {
        self.recipeRepositoryName = recipeRepositoryName
        self.recipeRepositoryKind = recipeRepositoryKind
    }
}
