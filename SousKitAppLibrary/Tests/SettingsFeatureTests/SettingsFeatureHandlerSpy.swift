import RecipeLibrary
@testable import SettingsFeature

/// Records what the settings report.
@MainActor
final class SettingsFeatureHandlerSpy: SettingsFeatureHandler {
    private(set) var finishCount = 0
    private(set) var connectedRecipeRepositoryNames: [String] = []
    private(set) var selectedRecipeRepositoryKinds: [RecipeRepositoryKind] = []
    private(set) var resetCount = 0

    func settingsFeatureDidFinish() {
        finishCount += 1
    }

    func settingsFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository) {
        connectedRecipeRepositoryNames.append(recipeRepository.name)
    }

    func settingsFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        selectedRecipeRepositoryKinds.append(recipeRepositoryKind)
    }

    func settingsFeatureDidConfirmReset() {
        resetCount += 1
    }
}
