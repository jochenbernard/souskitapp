import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// A repository of no recipes.
struct EmptyRecipeRepository: RecipeRepository {
    let name: String

    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        AsyncStream(unfolding: { nil })
    }

    func refresh() {}

    func readRecipe(of _: RecipeEntry) throws -> Parsed<Recipe> {
        throw CocoaError(.fileReadNoSuchFile)
    }

    func readThumbnail(of _: RecipePicture, filling _: CGSize) throws -> CGImage {
        throw CocoaError(.fileReadNoSuchFile)
    }

    func recipeID(forFileAt _: URL) -> String? {
        nil
    }

    func exportRecipeFile(of _: RecipeEntry) throws -> URL {
        throw CocoaError(.fileReadNoSuchFile)
    }
}
