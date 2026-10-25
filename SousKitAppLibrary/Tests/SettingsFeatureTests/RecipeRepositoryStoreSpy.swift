import Foundation
import RecipeLibrary

/// Records the folders connected, failing every one where it is told to.
@MainActor
final class RecipeRepositoryStoreSpy: RecipeRepositoryStore {
    private(set) var connectedURLs: [URL] = []

    private let fails: Bool

    init(fails: Bool = false) {
        self.fails = fails
    }

    func makeRecipeRepository() -> RecipeRepository? {
        nil
    }

    func connectRecipeDirectory(at url: URL) throws -> RecipeRepository {
        guard !fails else {
            throw CocoaError(.fileReadNoPermission)
        }

        connectedURLs.append(url)

        return EmptyRecipeRepository(name: url.lastPathComponent)
    }

    func openRecipeDocument(at url: URL) -> RecipeDocument {
        let recipeRepository = EmptyRecipeRepository(name: url.deletingLastPathComponent().lastPathComponent)

        return RecipeDocument(
            url: url,
            entry: RecipeEntry(
                id: url.absoluteString,
                name: url.lastPathComponent,
                availability: .downloaded
            ),
            recipeRepository: recipeRepository
        )
    }

    func clear() {}
}
