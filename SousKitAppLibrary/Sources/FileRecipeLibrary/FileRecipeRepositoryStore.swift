import Foundation
import RecipeLibrary

/// The recipe directory the user picked, remembered across launches.
public struct FileRecipeRepositoryStore: RecipeRepositoryStore {
    nonisolated(unsafe) private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where the directory is remembered.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// The directory the user picked, or `nil` before they have picked one.
    ///
    /// Reading the directory's contents takes opening the URL's security scope first.
    var recipeDirectory: RecipeDirectory? {
        guard let data = userDefaults.data(forKey: Keys.bookmark) else {
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
        recipeDirectory.map({ FileRecipeRepository(recipeDirectory: $0) })
    }

    public func connectRecipeDirectory(at url: URL) throws -> RecipeRepository {
        try rememberRecipeDirectory(at: url)

        return FileRecipeRepository(recipeDirectory: RecipeDirectory(url: url))
    }

    public func clear() {
        userDefaults.removeObject(forKey: Keys.bookmark)
    }

    private func rememberRecipeDirectory(at url: URL) throws {
        let data = try url.withSecurityScope({ try url.bookmarkData() })
        userDefaults.set(data, forKey: Keys.bookmark)
    }

    private enum Keys {
        static let bookmark = "FileRecipeRepositoryStore.bookmark"
    }
}
