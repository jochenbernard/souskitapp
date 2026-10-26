import Observation

@Observable
@MainActor
final class KitchenFeatureViewModel {
    let recipeRepositoryName: String
    var greeting: KitchenGreeting = .morning
    var recipeList: KitchenRecipeList = .reading
    var isRestoring = false
    var isPushingRestoredRecipe = false
    var searches: [[String]: KitchenSearch] = [:]
    var pushedScreens: [KitchenScreen] = []
    var openRecipe: OpenRecipe?
    var previewedRecipe: OpenRecipe?
    // The folder whose search field is active, by its path, or `nil` where none is; the top's path is empty.
    // swiftlint:disable:next discouraged_optional_collection
    var presentedSearchPath: [String]?
    var zoomedRecipeIDs: Set<String> = []
    var openCooking: OpenCooking?
    var sharedFile: SharedRecipeFile?
    let thumbnails = KitchenThumbnails()
    let symbols = KitchenSymbols()

    nonisolated init(recipeRepositoryName: String) {
        self.recipeRepositoryName = recipeRepositoryName
    }
}
