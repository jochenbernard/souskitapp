@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@MainActor
@Suite("File recipe repository store")
final class FileRecipeRepositoryStoreTests {
    private let parser = SousParser()

    private let caches: TemporaryDirectory
    private let directory: TemporaryDirectory
    private let suiteName: String
    private let userDefaults: UserDefaults

    init() throws {
        self.caches = try TemporaryDirectory(named: "FileRecipeRepositoryStoreTests")
        self.directory = try TemporaryDirectory(named: "FileRecipeRepositoryStoreTests")
        self.suiteName = directory.url.lastPathComponent
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// A store remembering its directory in this suite's defaults, and keeping what it reads in this suite's caches.
    private func makeStore() -> FileRecipeRepositoryStore {
        FileRecipeRepositoryStore(
            parser: parser,
            symbolPicker: RecipeSymbolPickerStub(),
            userDefaults: userDefaults,
            cachesDirectory: caches.url
        )
    }

    /// The path a URL points at, with the symlinks in front of a temporary directory taken out.
    private func resolvedPath(of url: URL) -> [String] {
        url.resolvingSymlinksInPath().pathComponents
    }

    @Test("nothing is remembered before a directory is connected")
    func emptyStore() {
        let store = makeStore()

        #expect(store.recipeDirectory == nil)
        #expect(store.makeRecipeRepository() == nil)
    }

    @Test("connecting a directory returns a repository named after it")
    func connecting() throws {
        let store = makeStore()

        let recipeRepository = try store.connectRecipeDirectory(at: directory.url)

        #expect(recipeRepository.name == suiteName)
    }

    @Test("a directory connected is read back by a store built later")
    func roundTrip() throws {
        _ = try makeStore().connectRecipeDirectory(at: directory.url)

        let store = makeStore()
        let remembered = try #require(store.recipeDirectory)
        #expect(resolvedPath(of: remembered.url) == resolvedPath(of: directory.url))
        #expect(store.makeRecipeRepository()?.name == suiteName)
    }

    @Test("the last directory connected is the one remembered")
    func lastOneWins() throws {
        let store = makeStore()
        let other = directory.url.appending(path: "Elsewhere")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)

        _ = try store.connectRecipeDirectory(at: directory.url)
        _ = try store.connectRecipeDirectory(at: other)

        #expect(store.makeRecipeRepository()?.name == "Elsewhere")
    }

    @Test("clearing forgets the directory, and the summaries and thumbnails kept of its recipes")
    func clearing() throws {
        let store = makeStore()
        _ = try store.connectRecipeDirectory(at: directory.url)
        try caches.writeFile(named: "RecipeSummaries.json")
        try caches.makeDirectory(named: "RecipeThumbnails")
        try caches.writeFile(named: "RecipeThumbnails/thumbnail")

        store.clear()

        #expect(store.makeRecipeRepository() == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: caches.url.path(percentEncoded: false)).isEmpty)
    }

    @Test("a bookmark that no longer resolves reads back as nothing remembered")
    func unresolvableBookmark() throws {
        let store = makeStore()
        let removed = directory.url.appending(path: "Removed")
        try FileManager.default.createDirectory(at: removed, withIntermediateDirectories: true)
        _ = try store.connectRecipeDirectory(at: removed)

        try FileManager.default.removeItem(at: removed)

        #expect(store.makeRecipeRepository() == nil)
    }
}
