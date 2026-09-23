import Observation
import RecipeLibrary

@Observable
@MainActor
final class RecipeFeatureViewModel {
    let recipeEntry: RecipeEntry
    var recipeContent: RecipeContent = .reading
    var expandedSections = RecipeSection.openByDefault
    var isScaling = false
    var scaleText = ""

    nonisolated init(recipeEntry: RecipeEntry) {
        self.recipeEntry = recipeEntry
    }
}
