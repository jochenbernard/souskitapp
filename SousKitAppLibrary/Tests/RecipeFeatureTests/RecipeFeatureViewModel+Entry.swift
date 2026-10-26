@testable import RecipeFeature
import RecipeLibrary
import SousKit

extension RecipeFeatureViewModel {
    /// A view model for a recipe at the top of its repository.
    convenience init(recipeEntry: RecipeEntry) {
        self.init(
            recipeEntry: recipeEntry,
            folderPath: ["Recipes"],
            placeholderRecipe: .placeholder(parser: SousParser())
        )
    }
}
