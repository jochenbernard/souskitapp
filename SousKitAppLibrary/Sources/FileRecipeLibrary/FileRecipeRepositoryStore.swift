import Foundation
import RecipeLibrary
import SousKit

/// The recipe directory the user picked, remembered across launches.
@MainActor
public struct FileRecipeRepositoryStore: RecipeRepositoryStore {
    private static let key = "FileRecipeRepositoryStore.bookmark"

    // Caches, not the recipe directory: the summaries are rebuilt from the recipes wherever the system clears them.
    private static let summaryCacheURL = URL.cachesDirectory.appending(path: "RecipeSummaries.json")

    // Caches as well: a thumbnail is made again from its picture wherever the system clears it.
    private static let thumbnailCacheURL = URL.cachesDirectory.appending(
        path: "RecipeThumbnails",
        directoryHint: .isDirectory
    )

    private let parser: SousParser
    private let symbolPicker: RecipeSymbolPicker
    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameters:
    ///   - parser: What the recipes in the directory are read with.
    ///   - symbolPicker: What the recipes' symbols are picked with.
    ///   - userDefaults: Where the directory is remembered.
    public init(
        parser: SousParser,
        symbolPicker: RecipeSymbolPicker,
        userDefaults: UserDefaults = .standard
    ) {
        self.parser = parser
        self.symbolPicker = symbolPicker
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

    public func openRecipeDocument(at url: URL) -> RecipeDocument {
        let recipeRepository = RecipeDocumentRepository(url: url, parser: parser)

        return RecipeDocument(
            url: url,
            entry: recipeRepository.entry,
            recipeRepository: recipeRepository
        )
    }

    public func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }

    private func makeRecipeRepository(reading recipeDirectory: RecipeDirectory) -> FileRecipeRepository {
        FileRecipeRepository(
            parser: parser,
            recipeDirectory: recipeDirectory,
            symbolPicker: symbolPicker,
            summaryCacheURL: Self.summaryCacheURL,
            thumbnailCacheURL: Self.thumbnailCacheURL
        )
    }

    private func rememberRecipeDirectory(at url: URL) throws {
        let data = try url.withSecurityScope({ try url.bookmarkData() })
        userDefaults.set(data, forKey: Self.key)
    }
}
