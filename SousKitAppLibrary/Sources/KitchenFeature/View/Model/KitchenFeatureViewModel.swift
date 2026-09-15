import Observation

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeRepositoryName: String
    var recipeList: KitchenRecipeList = .reading
    var screenPath: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var openCooking: OpenCooking?
    var isConfirmingReset = false

    nonisolated init(recipeRepositoryName: String) {
        self.recipeRepositoryName = recipeRepositoryName
    }
}
