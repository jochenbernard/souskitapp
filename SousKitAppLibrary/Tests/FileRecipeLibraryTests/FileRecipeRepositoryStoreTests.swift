import CoreGraphics
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
    private let temporary: TemporaryDirectory
    private let userDefaults: UserDefaults

    init() throws {
        self.caches = try TemporaryDirectory(named: "FileRecipeRepositoryStoreTests")
        self.directory = try TemporaryDirectory(named: "FileRecipeRepositoryStoreTests")
        self.suiteName = directory.url.lastPathComponent
        self.temporary = try TemporaryDirectory(named: "FileRecipeRepositoryStoreTests")
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// A store remembering its directory in this suite's defaults, and keeping what it reads in this suite's caches
    /// and temporary directory.
    private func makeStore() -> FileRecipeRepositoryStore {
        FileRecipeRepositoryStore(
            parser: parser,
            symbolPicker: RecipeSymbolPickerStub(),
            userDefaults: userDefaults,
            cachesDirectory: caches.url,
            temporaryDirectory: temporary.url
        )
    }

    /// The names of what a directory holds.
    private func contents(of directory: TemporaryDirectory) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.url.path(percentEncoded: false))
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

    @Test("clearing forgets the directory, the summaries and thumbnails kept of its recipes, and their files exported")
    func clearing() async throws {
        let store = makeStore()
        let recipeRepository = try store.connectRecipeDirectory(at: directory.url)
        try caches.writeFile(named: "RecipeSummaries.json")
        try caches.makeDirectory(named: "RecipeThumbnails")
        try caches.writeFile(named: "RecipeThumbnails/thumbnail")
        let crepes = try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        _ = try await recipeRepository.exportRecipeFile(of: crepes)
        _ = try await recipeRepository.exportRecipeFile(of: crepes)
        try #require(try !contents(of: temporary).isEmpty)

        store.clear()

        #expect(store.makeRecipeRepository() == nil)
        #expect(try contents(of: caches).isEmpty)
        #expect(try contents(of: temporary).isEmpty)
    }

    @Test("a repository a store makes reads the thumbnails kept for the first pictures ahead of the kitchen")
    func thumbnailsReadAhead() async throws {
        let store = makeStore()
        let pictures = try await keepThumbnails(named: ["brioche", "crepes"], with: store)
        // Connected again rather than made from the bookmark, which resolves the temporary directory's path otherwise.
        let recipeRepository = try store.connectRecipeDirectory(at: directory.url)

        #expect(await recipeRepository.cachedThumbnail(of: pictures[0]) != nil)

        try FileManager.default.removeItem(at: caches.url.appending(path: "RecipeThumbnails"))

        #expect(await recipeRepository.cachedThumbnail(of: pictures[1]) != nil)
    }

    @Test("clearing while a repository reads ahead leaves nothing in the caches")
    func clearingDuringReadAhead() async throws {
        let store = makeStore()
        let pictures = try await keepThumbnails(named: ["brioche", "crepes"], with: store)
        // Connected again rather than made from the bookmark, which resolves the temporary directory's path otherwise.
        let recipeRepository = try store.connectRecipeDirectory(at: directory.url)

        store.clear()

        for picture in pictures {
            _ = await recipeRepository.cachedThumbnail(of: picture)
        }

        #expect(try contents(of: caches).isEmpty)
    }

    /// Connects the directory holding recipes of the names given, each naming a picture, and reads their summaries and
    /// thumbnails, so the caches hold both as after an earlier launch.
    ///
    /// - Returns: The pictures, in the order of the names.
    private func keepThumbnails(
        named names: [String],
        with store: FileRecipeRepositoryStore
    ) async throws -> [RecipePicture] {
        for name in names {
            try directory.writePicture(
                named: "\(name).png",
                width: 800,
                height: 500
            )
            try directory.writeFile(named: "\(name).sous", "---\ntitle: \(name)\nimage: \(name).png\n---")
        }

        let recipeRepository = try store.connectRecipeDirectory(at: directory.url)
        var pictures: [RecipePicture] = []

        for await result in await recipeRepository.listedRecipes() {
            pictures = try result.get().compactMap(\.entry.picture)

            if pictures.count == names.count {
                break
            }
        }

        for picture in pictures {
            _ = try await recipeRepository.readThumbnail(of: picture, filling: CGSize(width: 400.0, height: 250.0))
        }

        return pictures
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
