@testable import KitchenFeature
import RecipeLibrary

/// A handler that keeps the kinds of repository picked and counts the resets reported to it.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
    private(set) var selectedRecipeRepositoryKinds: [RecipeRepositoryKind] = []
    private(set) var resetCount = 0

    func kitchenFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        selectedRecipeRepositoryKinds.append(recipeRepositoryKind)
    }

    func kitchenFeatureDidConfirmReset() {
        resetCount += 1
    }
}
