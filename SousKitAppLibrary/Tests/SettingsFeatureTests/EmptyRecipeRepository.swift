import Foundation
import RecipeLibrary
import SousKit

/// A repository of no recipes.
struct EmptyRecipeRepository: RecipeRepository {
    let name: String

    func recipeEntries() -> AsyncStream<Result<[RecipeEntry], Error>> {
        AsyncStream(unfolding: { nil })
    }

    func refresh() {}

    func readRecipe(of _: RecipeEntry) throws -> Parsed<Recipe> {
        throw CocoaError(.fileReadNoSuchFile)
    }
}
