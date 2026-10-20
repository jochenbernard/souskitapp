@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

extension FileRecipeRepositoryTests {
    private typealias Iterator = AsyncStream<Result<[ListedRecipe], Error>>.Iterator

    /// Writes `crepes.sous` with the tags and servings given.
    private func writeCrepes(tags: String = "dessert, classic, french", servings: Int = 4) throws {
        try directory.writeFile(
            named: "crepes.sous",
            "---\ntitle: Crepes\nservings: \(servings)\ntags: [\(tags)]\n---\n\nWhisk @{200 g} flour@ with @{4} eggs@."
        )
    }

    /// The next recipes the stream lists that `condition` holds for.
    @MainActor
    private func listedRecipes(
        from iterator: inout Iterator,
        where condition: ([ListedRecipe]) -> Bool
    ) async throws -> [ListedRecipe] {
        while let listing = await iterator.next(isolation: #isolation) {
            let listedRecipes = try listing.get()

            if condition(listedRecipes) {
                return listedRecipes
            }
        }

        Issue.record("The stream ended first.")
        return []
    }

    /// Waits until the cache file holds a pick for `crepes.sous`, which it writes a while after the pick lands.
    private func waitForCachedPick() async throws {
        while directory.summaryCache.load()["crepes.sous"]?.symbolPick == nil {
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private static func symbol(in listedRecipes: [ListedRecipe]) -> String? {
        listedRecipes.first?.symbolPick?.symbol
    }

    @MainActor
    @Test("a symbol picked for a recipe is listed with it, and listed at once on the next launch without asking again")
    func pickKeptAcrossLaunches() async throws {
        try writeCrepes()
        let picker = RecipeSymbolPickerStub()
        picker.symbols = ["Crepes": "birthday.cake"]
        let repository = makeRepository(symbolPicker: picker)
        var iterator = await repository.listedRecipes().makeAsyncIterator()

        let picked = try await listedRecipes(from: &iterator, where: { Self.symbol(in: $0) != nil })

        #expect(Self.symbol(in: picked) == "birthday.cake")

        try await waitForCachedPick()
        let relaunchPicker = RecipeSymbolPickerStub()
        let relaunchedRepository = makeRepository(symbolPicker: relaunchPicker)
        var relaunched = await relaunchedRepository.listedRecipes().makeAsyncIterator()
        let first = try #require(await relaunched.next()).get()
        try await Task.sleep(for: .milliseconds(200))

        #expect(Self.symbol(in: first) == "birthday.cake")
        #expect(relaunchPicker.inputs.isEmpty)
    }

    @MainActor
    @Test("changing what the symbol was picked from picks it again, and changing anything else does not")
    func pickAskedAgain() async throws {
        try writeCrepes()
        let picker = RecipeSymbolPickerStub()
        picker.symbols = ["Crepes": "birthday.cake"]
        let repository = makeRepository(symbolPicker: picker)
        var iterator = await repository.listedRecipes().makeAsyncIterator()
        _ = try await listedRecipes(from: &iterator, where: { Self.symbol(in: $0) != nil })

        try writeCrepes(servings: 6)
        let served = try await listedRecipes(from: &iterator) { listedRecipes in
            listedRecipes.first?.entry.summary?.metadata.servings == 6.0
        }
        try await Task.sleep(for: .milliseconds(200))

        #expect(Self.symbol(in: served) == "birthday.cake")
        #expect(picker.inputs.count == 1)

        picker.symbols = ["Crepes": "frying.pan"]
        try writeCrepes(tags: "breakfast", servings: 6)
        let retagged = try await listedRecipes(from: &iterator, where: { Self.symbol(in: $0) == "frying.pan" })

        #expect(picker.inputs.map(\.tags) == [["dessert", "classic", "french"], ["breakfast"]])
        #expect(retagged.first?.entry.summary?.metadata.tags == ["breakfast"])
    }

    @MainActor
    @Test("where symbols cannot be picked, the recipes are listed with none")
    func unavailablePicker() async throws {
        try writeCrepes()
        let picker = RecipeSymbolPickerStub(isAvailable: false)
        picker.symbols = ["Crepes": "birthday.cake"]
        let repository = makeRepository(symbolPicker: picker)
        var iterator = await repository.listedRecipes().makeAsyncIterator()

        let read = try await listedRecipes(from: &iterator, where: { $0.first?.entry.summary != nil })
        try await Task.sleep(for: .milliseconds(200))

        #expect(Self.symbol(in: read) == nil)
        #expect(picker.inputs.isEmpty)
    }
}
