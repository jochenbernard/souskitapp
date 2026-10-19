import Foundation
import RecipeLibrary
import SousKit

/// The recipe directory the user picked, remembered across launches.
@MainActor
public struct FileRecipeRepositoryStore: RecipeRepositoryStore {
    private static let key = "FileRecipeRepositoryStore.bookmark"

    // Caches, not the recipe directory: the summaries are rebuilt from the recipes wherever the system clears them.
    private static let summaryCacheURL = URL.cachesDirectory.appending(path: "RecipeSummaries.json")

    private let parser: SousParser
    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameters:
    ///   - parser: What the recipes in the directory are read with.
    ///   - userDefaults: Where the directory is remembered.
    public init(
        parser: SousParser,
        userDefaults: UserDefaults = .standard
    ) {
        self.parser = parser
        self.userDefaults = userDefaults
    }

    /// The directory the user picked, or `nil` before they have picked one.
    ///
    /// Reading the directory's contents takes opening the URL's security scope first.
    var recipeDirectory: RecipeDirectory? {
        guard let data = userDefaults.data(forKey: Self.key) else {
            return nil
        }

        var isStale = false
        let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)

        guard let url else {
            return nil
        }

        if isStale {
            try? rememberRecipeDirectory(at: url)
        }

        return RecipeDirectory(url: url)
    }

    public func makeRecipeRepository() -> RecipeRepository? {
        recipeDirectory.map(makeRecipeRepository(reading:))
    }

    public func connectRecipeDirectory(at url: URL) throws -> RecipeRepository {
        try rememberRecipeDirectory(at: url)

        return makeRecipeRepository(reading: RecipeDirectory(url: url))
    }

    public func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }

    private func makeRecipeRepository(reading recipeDirectory: RecipeDirectory) -> FileRecipeRepository {
        FileRecipeRepository(
            parser: parser,
            recipeDirectory: recipeDirectory,
            summaryCacheURL: Self.summaryCacheURL
        )
    }

    private func rememberRecipeDirectory(at url: URL) throws {
        let data = try url.withSecurityScope({ try url.bookmarkData() })
        userDefaults.set(data, forKey: Self.key)
    }
}
