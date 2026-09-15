import Foundation

/// The recipe directory, remembered across launches.
///
/// A directory the user picks is reachable only through a bookmark taken while picking it, so
/// this keeps the bookmark rather than the path.
public struct RecipeDirectoryStore: Sendable {
    nonisolated(unsafe) private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where the bookmark is kept.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// The directory the user picked, or `nil` before they have picked one.
    ///
    /// Reading the directory's contents takes opening the URL's security scope first. A bookmark
    /// the system reports as stale is rewritten here, so the next launch resolves it directly.
    public var recipeDirectory: RecipeDirectory? {
        guard let data = userDefaults.data(forKey: Keys.bookmark) else {
            return nil
        }

        var isStale = false
        let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)

        guard let url else {
            return nil
        }

        if isStale {
            try? setRecipeDirectory(at: url)
        }

        return RecipeDirectory(url: url)
    }

    /// Records the directory at a URL as the one recipes are read from.
    ///
    /// - Parameter url: The directory the user picked.
    /// - Throws: Whatever bookmarking `url` throws.
    public func setRecipeDirectory(at url: URL) throws {
        let data = try url.withSecurityScope({ try url.bookmarkData() })
        userDefaults.set(data, forKey: Keys.bookmark)
    }

    /// Forgets the directory, leaving the app nowhere to read recipes from.
    public func clear() {
        userDefaults.removeObject(forKey: Keys.bookmark)
    }

    private enum Keys {
        static let bookmark = "RecipeDirectoryStore.bookmark"
    }
}
