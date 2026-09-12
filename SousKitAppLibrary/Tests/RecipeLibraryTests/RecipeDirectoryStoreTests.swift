import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory store")
final class RecipeDirectoryStoreTests {
    private let directory: TemporaryDirectory
    private let suiteName: String
    private let userDefaults: UserDefaults

    init() throws {
        directory = try TemporaryDirectory(named: "RecipeDirectoryStoreTests")
        suiteName = directory.url.lastPathComponent
        userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// The path a URL points at, with the symlinks in front of a temporary directory taken out.
    private func resolvedPath(of url: URL) -> String {
        RecipeDirectory(url: url.resolvingSymlinksInPath()).path
    }

    @Test("nothing is remembered before a directory is set")
    func emptyStore() {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        #expect(store.recipeDirectory == nil)
    }

    @Test("a directory set is read back by a store built later")
    func roundTrip() throws {
        try RecipeDirectoryStore(userDefaults: userDefaults).setRecipeDirectory(at: directory.url)

        let remembered = try #require(RecipeDirectoryStore(userDefaults: userDefaults).recipeDirectory)
        #expect(resolvedPath(of: remembered.url) == resolvedPath(of: directory.url))
        #expect(remembered.name == suiteName)
    }

    @Test("the last directory set is the one remembered")
    func lastOneWins() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        let other = directory.url.appending(path: "Elsewhere")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)

        try store.setRecipeDirectory(at: directory.url)
        try store.setRecipeDirectory(at: other)

        #expect(store.recipeDirectory?.name == "Elsewhere")
    }

    @Test("clearing forgets the directory")
    func clearing() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        try store.setRecipeDirectory(at: directory.url)

        store.clear()

        #expect(store.recipeDirectory == nil)
    }

    @Test("a bookmark that no longer resolves reads back as nothing remembered")
    func unresolvableBookmark() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        let removed = directory.url.appending(path: "Removed")
        try FileManager.default.createDirectory(at: removed, withIntermediateDirectories: true)
        try store.setRecipeDirectory(at: removed)

        try FileManager.default.removeItem(at: removed)

        #expect(store.recipeDirectory == nil)
    }
}
