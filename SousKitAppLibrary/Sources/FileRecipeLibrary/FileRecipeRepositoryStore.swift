import Foundation
import RecipeLibrary
import SousKit

/// The recipe directory the user picked, remembered across launches.
@MainActor
public struct FileRecipeRepositoryStore: RecipeRepositoryStore {
    private static let key = "FileRecipeRepositoryStore.bookmark"

    private let cachesDirectory: URL
    private let parser: SousParser
    private let symbolPicker: RecipeSymbolPicker
    private let temporaryDirectory: URL
    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameters:
    ///   - parser: What the recipes in the directory are read with.
    ///   - symbolPicker: What the recipes' symbols are picked with.
    ///   - userDefaults: Where the directory is remembered.
    ///   - cachesDirectory: Where what is read from the directory is kept, outside it.
    ///   - temporaryDirectory: Where the directory's recipe files are copied for handing them to other apps.
    public init(
        parser: SousParser,
        symbolPicker: RecipeSymbolPicker,
        userDefaults: UserDefaults = .standard,
        cachesDirectory: URL = .cachesDirectory,
        temporaryDirectory: URL = .temporaryDirectory
    ) {
        self.cachesDirectory = cachesDirectory
        self.parser = parser
        self.symbolPicker = symbolPicker
        self.temporaryDirectory = temporaryDirectory
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

    // Caches, not the recipe directory: the summaries are rebuilt from the recipes wherever the system clears them.
    private var summaryCacheURL: URL {
        cachesDirectory.appending(path: "RecipeSummaries.json")
    }

    // Caches as well: a thumbnail is made again from its picture wherever the system clears it.
    private var thumbnailCacheURL: URL {
        cachesDirectory.appending(path: "RecipeThumbnails", directoryHint: .isDirectory)
    }

    // Temporary: a copy is wanted only until the app it is handed to has taken it.
    private var exportFolderURL: URL {
        temporaryDirectory.appending(path: "RecipeExports", directoryHint: .isDirectory)
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
        RecipeSummaryCache.clear(fileURL: summaryCacheURL)
        RecipeThumbnailCache.clear(folderURL: thumbnailCacheURL)
        try? FileManager.default.removeItem(at: exportFolderURL)
    }

    private func makeRecipeRepository(reading recipeDirectory: RecipeDirectory) -> FileRecipeRepository {
        FileRecipeRepository(
            parser: parser,
            recipeDirectory: recipeDirectory,
            symbolPicker: symbolPicker,
            summaryCacheURL: summaryCacheURL,
            thumbnailCacheURL: thumbnailCacheURL,
            exportFolderURL: exportFolderURL
        )
    }

    private func rememberRecipeDirectory(at url: URL) throws {
        let data = try url.withSecurityScope({ try url.bookmarkData() })
        userDefaults.set(data, forKey: Self.key)
    }
}
