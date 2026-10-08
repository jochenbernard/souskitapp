@testable import KitchenFeature
import RecipeLibrary

/// A handler that keeps the kinds of repository picked and counts the folders connected and the resets reported to it.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
    private(set) var connectCount = 0
    private(set) var selectedRecipeRepositoryKinds: [RecipeRepositoryKind] = []
    private(set) var resetCount = 0

    func kitchenFeatureDidConnectRecipeRepository(_: RecipeRepository) {
        connectCount += 1
    }

    func kitchenFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        selectedRecipeRepositoryKinds.append(recipeRepositoryKind)
    }

    func kitchenFeatureDidConfirmReset() {
        resetCount += 1
    }
}
