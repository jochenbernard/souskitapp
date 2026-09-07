import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory store")
final class RecipeDirectoryStoreTests {
    private let directoryURL: URL
    private let suiteName: String
    private let userDefaults: UserDefaults

    init() throws {
        let name = "RecipeDirectoryStoreTests.\(UUID().uuidString)"
        let url = URL(filePath: NSTemporaryDirectory()).appending(path: name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        directoryURL = url
        suiteName = name
        userDefaults = try #require(UserDefaults(suiteName: name))
    }

    deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directoryURL)
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
        try RecipeDirectoryStore(userDefaults: userDefaults).setRecipeDirectory(at: directoryURL)

        let remembered = try #require(RecipeDirectoryStore(userDefaults: userDefaults).recipeDirectory)
        #expect(resolvedPath(of: remembered.url) == resolvedPath(of: directoryURL))
        #expect(remembered.name == suiteName)
    }

    @Test("the last directory set is the one remembered")
    func lastOneWins() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        let other = directoryURL.appending(path: "Elsewhere")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)

        try store.setRecipeDirectory(at: directoryURL)
        try store.setRecipeDirectory(at: other)

        #expect(store.recipeDirectory?.name == "Elsewhere")
    }

    @Test("clearing forgets the directory")
    func clearing() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        try store.setRecipeDirectory(at: directoryURL)

        store.clear()

        #expect(store.recipeDirectory == nil)
    }

    @Test("a bookmark that no longer resolves reads back as nothing remembered")
    func unresolvableBookmark() throws {
        let store = RecipeDirectoryStore(userDefaults: userDefaults)
        let removed = directoryURL.appending(path: "Removed")
        try FileManager.default.createDirectory(at: removed, withIntermediateDirectories: true)
        try store.setRecipeDirectory(at: removed)

        try FileManager.default.removeItem(at: removed)

        #expect(store.recipeDirectory == nil)
    }
}
