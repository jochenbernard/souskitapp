import CoreTransferable
import Foundation
@testable import RecipeFeature
import RecipeLibrary
import Testing

@Suite("Shared recipe", .timeLimit(.minutes(1)))
struct SharedRecipeTests {
    @Test("a shared recipe hands on its file as the repository exports it")
    func exportsTheFile() async throws {
        let text = "Whisk @{200 g} flour@ into a batter with @{4} eggs@."
        let sharedRecipe = SharedRecipe(
            entry: RecipeEntry(
                id: "crepes",
                name: "crepes",
                availability: .downloaded
            ),
            recipeRepository: RecipeRepositoryStub(text: text)
        )

        #expect(try await sharedRecipe.exported(as: .sousRecipe) == Data(text.utf8))
    }

    @Test("a recipe that cannot be exported hands on nothing")
    func failedExport() async {
        let sharedRecipe = SharedRecipe(
            entry: RecipeEntry(
                id: "crepes",
                name: "crepes",
                availability: .downloaded
            ),
            recipeRepository: RecipeRepositoryStub(text: nil)
        )

        await #expect(throws: (any Error).self) {
            try await sharedRecipe.exported(as: .sousRecipe)
        }
    }
}
