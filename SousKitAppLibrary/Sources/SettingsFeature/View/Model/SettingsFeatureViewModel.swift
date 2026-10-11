import Observation
import RecipeLibrary
import RecipeScaling

@Observable
@MainActor
final class SettingsFeatureViewModel {
    let recipeRepositoryName: String
    let recipeRepositoryKind: RecipeRepositoryKind
    var selectedRecipeRepositoryKind: RecipeRepositoryKind
    let appVersion: AppVersion
    var scale: RecipeScale
    var scaleText: String
    var isScaling = false
    var isChoosingDirectory = false
    var failureMessage: String?
    var isConfirmingReset = false

    init(
        recipeRepositoryName: String,
        recipeRepositoryKind: RecipeRepositoryKind,
        appVersion: AppVersion,
        scale: RecipeScale
    ) {
        self.recipeRepositoryName = recipeRepositoryName
        self.recipeRepositoryKind = recipeRepositoryKind
        self.selectedRecipeRepositoryKind = recipeRepositoryKind
        self.appVersion = appVersion
        self.scale = scale
        self.scaleText = ScaleNumber.text(scale.value)
    }
}
