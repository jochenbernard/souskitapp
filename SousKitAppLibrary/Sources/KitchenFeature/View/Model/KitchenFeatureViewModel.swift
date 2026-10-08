import Observation

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeRepositoryName: String
    var recipeList: KitchenRecipeList = .reading
    var isRestoring = false
    var screenPath: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var openCooking: OpenCooking?
    var openSettings: OpenSettings?

    nonisolated init(recipeRepositoryName: String) {
        self.recipeRepositoryName = recipeRepositoryName
    }
}
