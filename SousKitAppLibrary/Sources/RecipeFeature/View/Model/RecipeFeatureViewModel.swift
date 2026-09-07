import Observation
import RecipeLibrary

@Observable
@MainActor
final class RecipeFeatureViewModel {
    let recipeFile: RecipeFile
    var recipeContent: RecipeContent = .reading

    nonisolated init(recipeFile: RecipeFile) {
        self.recipeFile = recipeFile
    }
}
