import Foundation
import RecipeLibrary
import SousKit

/// A repository reading every recipe as one text, or failing every read where it holds none.
struct RecipeRepositoryStub: RecipeRepository {
    let name = "Recipes"

    private let parser = SousParser()
    private let text: String?

    init(text: String?) {
        self.text = text
    }

    func recipeEntries() -> AsyncStream<Result<[RecipeEntry], Error>> {
        AsyncStream(unfolding: { nil })
    }

    func refresh() {}

    func readRecipe(of _: RecipeEntry) throws -> Parsed<Recipe> {
        guard let text else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return parser.parseRecipe(text)
    }
}
