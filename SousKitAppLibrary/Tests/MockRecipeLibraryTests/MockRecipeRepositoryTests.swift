import CoreGraphics
import Foundation
@testable import MockRecipeLibrary
import RecipeLibrary
import SousKit
import Testing

@Suite("Mock recipe repository", .timeLimit(.minutes(1)))
@MainActor
final class MockRecipeRepositoryTests {
    private let parser = SousParser()
    let symbolCacheURL = URL.temporaryDirectory.appending(
        path: "MockRecipeRepositoryTests-\(UUID().uuidString).json"
    )
    let exportFolderURL = URL.temporaryDirectory.appending(
        path: "MockRecipeRepositoryTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )

    isolated deinit {
        try? FileManager.default.removeItem(at: symbolCacheURL)
        try? FileManager.default.removeItem(at: exportFolderURL)
    }

    /// A repository picking no symbols unless given a picker that can, keeping them in this suite's file, and exporting
    /// into this suite's folder.
    @MainActor
    func makeRepository(
        symbolPicker: RecipeSymbolPicker = RecipeSymbolPickerStub(isAvailable: false)
    ) -> MockRecipeRepository {
        MockRecipeRepository(
            parser: parser,
            symbolPicker: symbolPicker,
            symbolCacheURL: symbolCacheURL,
            exportFolderURL: exportFolderURL,
            fetchDuration: .zero
        )
    }

    /// The first list a new stream from the repository yields, which is the recipes as they are now.
    @MainActor
    private func currentRecipeEntries(of repository: MockRecipeRepository) async throws -> [RecipeEntry] {
        try await currentListedRecipes(of: repository).map(\.entry)
    }

    /// The first list a new stream from the repository yields, with the recipes' ingredient names.
    @MainActor
    func currentListedRecipes(of repository: MockRecipeRepository) async throws -> [ListedRecipe] {
        var iterator = repository.listedRecipes().makeAsyncIterator()

        return try #require(await iterator.next()).get()
    }

    @MainActor
    func currentRecipeEntry(
        withID id: String,
        of repository: MockRecipeRepository
    ) async throws -> RecipeEntry {
        try #require(try await currentRecipeEntries(of: repository).first(where: { $0.id == id }))
    }

    @Test("every recipe listed has a text to read but the unreachable one")
    func onlyTheUnreachableRecipeHasNoText() {
        #expect(MockRecipe.all.filter({ $0.isListed && $0.text == nil }).map(\.id) == ["unreachable.sous"])
    }

    @MainActor
    @Test("the recipes are listed by where they sit, as a folder lists them")
    func listedByPath() async throws {
        let ids = try await currentRecipeEntries(of: makeRepository()).map(\.id)

        #expect(ids == ids.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }))
    }

    @MainActor
    @Test("recipes in folders are listed with the folders leading down to them, at any depth")
    func folderPaths() async throws {
        let repository = makeRepository()

        #expect(try await currentRecipeEntry(withID: "crepes.sous", of: repository).folderPath.isEmpty)
        #expect(try await currentRecipeEntry(withID: "Baking/crepes.sous", of: repository).folderPath == ["Baking"])
        #expect(
            try await currentRecipeEntry(withID: "French/Comfort food/gratin-dauphinois.sous", of: repository)
                .folderPath == ["French", "Comfort food"]
        )
        #expect(
            try await currentRecipeEntry(withID: "Lunch/French/Classic/croque-monsieur.sous", of: repository)
                .folderPath == ["Lunch", "French", "Classic"]
        )
    }

    @MainActor
    @Test("recipes sharing a file name in different folders are listed apart, under the same name")
    func sameFileNameInTwoFolders() async throws {
        let entries = try await currentRecipeEntries(of: makeRepository())
        let brioches = entries.filter({ $0.name == "brioche" })

        #expect(brioches.map(\.id) == ["Baking/brioche.sous", "brioche.sous"])
    }

    @MainActor
    @Test("a hidden folder and what is not a recipe are left out")
    func unlistedFiles() async throws {
        let ids = try await currentRecipeEntries(of: makeRepository()).map(\.id)

        #expect(!ids.contains(where: { $0.hasPrefix(".archive/") || $0.hasPrefix("images/") }))
        #expect(MockRecipe.all.contains(where: { $0.path.hasPrefix(".archive/") }))
        #expect(MockRecipe.all.contains(where: { $0.path.hasPrefix("images/") }))
    }

    @MainActor
    @Test("every recipe with a text is listed with its summary, the ones in iCloud included")
    func summaries() async throws {
        let entries = try await currentRecipeEntries(of: makeRepository())

        #expect(entries.filter({ $0.summary == nil }).map(\.id) == ["unreachable.sous"])
        #expect(entries.first(where: { $0.id == "crepes.sous" })?.title == "Crepes")
        #expect(entries.first(where: { $0.id == "crepes.sous" })?.availability == .notDownloaded)
        #expect(entries.first(where: { $0.id == "steps-only.sous" })?.title == "steps only")
    }

    @MainActor
    @Test("every listed recipe reads but the unreachable one")
    func everyRecipeReads() async throws {
        let repository = makeRepository()

        for recipeEntry in try await currentRecipeEntries(of: repository) where recipeEntry.id != "unreachable.sous" {
            _ = try await repository.readRecipe(of: recipeEntry)
        }
    }

    @MainActor
    @Test("a recipe in iCloud is listed as downloaded once it is read")
    func readRecipeComesDown() async throws {
        let repository = makeRepository()
        let crepes = try await currentRecipeEntry(withID: "crepes.sous", of: repository)

        _ = try await repository.readRecipe(of: crepes)

        #expect(crepes.availability == .notDownloaded)
        #expect(try await currentRecipeEntry(withID: "crepes.sous", of: repository).availability == .downloaded)
    }

    @MainActor
    @Test("a recipe on its way down lands without being read")
    func downloadingRecipeLands() async {
        let repository = makeRepository()
        var hasLanded = false

        // Waits for the landing, or for the suite's time limit to end the test.
        for await result in repository.listedRecipes()
        where (try? result.get())?.first(where: { $0.entry.id == "gratin-dauphinois.sous" })?.entry.availability
            == .downloaded {
            hasLanded = true
            break
        }

        // Releasing the repository ends the stream, which would end the wait for nothing.
        withExtendedLifetime(repository, {})
        #expect(hasLanded)
    }

    @MainActor
    @Test("a recipe is listed with the names of the ingredients it is made of, before it is read")
    func ingredientNamesAreListed() async throws {
        let listedRecipes = try await currentListedRecipes(of: makeRepository())
        let brioche = try #require(listedRecipes.first(where: { $0.entry.id == "brioche.sous" }))

        #expect(brioche.ingredientNames.contains("butter"))
        #expect(!brioche.ingredientNames.contains("foil"))
    }

    @MainActor
    @Test("the unreachable recipe fails to read and stays in iCloud")
    func unreachableRecipeFails() async throws {
        let repository = makeRepository()
        let unreachable = try await currentRecipeEntry(withID: "unreachable.sous", of: repository)

        await #expect(throws: CocoaError.self) {
            try await repository.readRecipe(of: unreachable)
        }
        #expect(try await currentRecipeEntry(withID: "unreachable.sous", of: repository).availability == .notDownloaded)
    }

    @MainActor
    @Test("listing the recipes again ends the stream listed before")
    func secondStreamEndsTheFirst() async throws {
        let repository = makeRepository()
        let first = repository.listedRecipes()
        _ = repository.listedRecipes()

        // The loop ends only once the stream does; the suite's time limit fails a stream left running.
        var lists: [[ListedRecipe]] = []
        for await result in first {
            lists.append(try result.get())
        }

        #expect(!lists.isEmpty)
    }

    @MainActor
    @Test("recipes are listed with the pictures their headers name where the folder holds them, and none elsewhere")
    func pictures() async throws {
        let pictures = Dictionary(
            uniqueKeysWithValues: try await currentRecipeEntries(of: makeRepository()).map({ ($0.id, $0.picture?.id) })
        )

        #expect(pictures["brioche.sous"] == "images/brioche.jpg")
        #expect(pictures["Baking/brioche.sous"] == "Baking/images/brioche.jpg")
        #expect(pictures["Baking/crepes.sous"] == "images/crepes.jpg")
        #expect(pictures["Dinner/Provencal/bouillabaisse.sous"] == "images/bouillabaisse.jpg")
        #expect(pictures["crepes.sous"] == .some(nil))
        #expect(pictures["bouillabaisse.sous"] == .some(nil))
        #expect(pictures["madeleines.sous"] == .some(nil))
        #expect(pictures["moules-marinieres.sous"] == .some(nil))
        #expect(pictures["quiche-lorraine.sous"] == .some(nil))
    }

    @MainActor
    @Test("a picture in iCloud lands without its recipe being read")
    func pictureInICloud() async throws {
        let repository = makeRepository()
        var availabilities: [RecipeAvailability?] = []

        for await result in repository.listedRecipes() {
            let gratin = try result.get().first(where: { $0.entry.id == "gratin-dauphinois.sous" })
            availabilities.append(gratin?.entry.picture?.availability)

            if availabilities.last == .downloaded {
                break
            }
        }

        // Releasing the repository ends the stream, which would end the wait for nothing.
        withExtendedLifetime(repository, {})
        #expect(availabilities.first == .notDownloaded)
        #expect(availabilities.last == .downloaded)
    }

    @MainActor
    @Test("a picture is drawn filling the box, and one that cannot be read fails")
    func thumbnails() async throws {
        let repository = makeRepository()
        let entries = try await currentRecipeEntries(of: repository)
        let brioche = try #require(entries.first(where: { $0.id == "brioche.sous" })?.picture)
        let croqueMonsieur = try #require(entries.first(where: { $0.id == "croque-monsieur.sous" })?.picture)
        let box = CGSize(width: 400.0, height: 300.0)

        let thumbnail = try await repository.readThumbnail(of: brioche, filling: box)

        #expect(thumbnail.width == 400)
        #expect(thumbnail.height == 534)
        await #expect(throws: CocoaError.self) {
            try await repository.readThumbnail(of: croqueMonsieur, filling: box)
        }
    }

    @MainActor
    @Test("the recipes are listed with the symbols picked for them as they land, and keep them in a new stream")
    func symbols() async throws {
        let picker = RecipeSymbolPickerStub()
        picker.symbols = ["Bouillabaisse": "fish", "Vinaigrette": "drop"]
        let repository = makeRepository(symbolPicker: picker)
        var iterator = repository.listedRecipes().makeAsyncIterator()

        while
            let listing = await iterator.next(),
            try listing.get().first(where: { $0.entry.id == "vinaigrette.sous" })?.symbolPick == nil
        {
            continue
        }

        let listedRecipes = try await currentListedRecipes(of: repository)
        let symbols = listedRecipes.reduce(into: [String: String]()) { symbols, listedRecipe in
            symbols[listedRecipe.entry.id] = listedRecipe.symbolPick?.symbol
        }

        #expect(symbols["bouillabaisse.sous"] == "fish")
        #expect(symbols["vinaigrette.sous"] == "drop")
        #expect(symbols["brioche.sous"] == nil)
    }

    @MainActor
    @Test("a symbol picked for a recipe is listed at once by the next launch's repository, which cannot pick")
    func symbolKeptAcrossLaunches() async throws {
        let picker = RecipeSymbolPickerStub()
        picker.symbols = ["Moules Marinieres": "fish"]
        let repository = makeRepository(symbolPicker: picker)
        var iterator = repository.listedRecipes().makeAsyncIterator()

        while
            let listing = await iterator.next(),
            try listing.get().first(where: { $0.entry.id == "Dinner/moules-marinieres.sous" })?.symbolPick == nil
        {
            continue
        }

        // The pick is kept after it is listed, before the next one is asked for.
        while MockSymbolCache(fileURL: symbolCacheURL).load()["Dinner/moules-marinieres.sous"] == nil {
            try await Task.sleep(for: .milliseconds(50))
        }

        let listedRecipes = try await currentListedRecipes(of: makeRepository())
        let moules = listedRecipes.first(where: { $0.entry.id == "Dinner/moules-marinieres.sous" })

        #expect(moules?.symbolPick?.symbol == "fish")
    }
}
