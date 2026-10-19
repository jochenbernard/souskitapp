import Observation

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeRepositoryName: String
    var recipeList: KitchenRecipeList = .reading
    var isRestoring = false
    var searches: [[String]: KitchenSearch] = [:]
    var pushedScreens: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var openCooking: OpenCooking?

    nonisolated init(recipeRepositoryName: String) {
        self.recipeRepositoryName = recipeRepositoryName
    }
}
