import Observation
import SousKit

@Observable
@MainActor
final class CookingFeatureViewModel {
    let recipe: Recipe
    var isConfirmingExit = false

    nonisolated init(recipe: Recipe) {
        self.recipe = recipe
    }
}
