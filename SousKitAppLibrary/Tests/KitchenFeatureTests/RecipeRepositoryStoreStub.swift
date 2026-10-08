import Foundation
import RecipeLibrary

/// Connects every folder to a repository listing nothing until a test sends it something.
@MainActor
final class RecipeRepositoryStoreStub: RecipeRepositoryStore {
    func makeRecipeRepository() -> RecipeRepository? {
        nil
    }

    func connectRecipeDirectory(at _: URL) -> RecipeRepository {
        RecipeRepositorySpy()
    }

    func clear() {}
}
