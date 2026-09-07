import Observation
import RecipeLibrary

@Observable
@MainActor
final class RecipeFeatureViewModel {
    let recipeFile: RecipeFile
    var recipeText: RecipeText = .reading

    nonisolated init(recipeFile: RecipeFile) {
        self.recipeFile = recipeFile
    }
}
