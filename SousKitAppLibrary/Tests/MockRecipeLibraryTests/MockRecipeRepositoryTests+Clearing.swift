@testable import MockRecipeLibrary
import RecipeLibrary
import Testing

extension MockRecipeRepositoryTests {
    @MainActor
    @Test("clearing forgets the symbols picked and the recipes fetched, the kept picks included")
    func clearing() async throws {
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

        while MockSymbolCache(fileURL: symbolCacheURL).load().isEmpty {
            try await Task.sleep(for: .milliseconds(50))
        }

        _ = try await repository.readRecipe(of: try await currentRecipeEntry(withID: "crepes.sous", of: repository))

        repository.clear()

        let listedRecipes = try await currentListedRecipes(of: repository)

        #expect(listedRecipes.allSatisfy({ $0.symbolPick == nil }))
        #expect(listedRecipes.first(where: { $0.entry.id == "crepes.sous" })?.entry.availability == .notDownloaded)
        #expect(MockSymbolCache(fileURL: symbolCacheURL).load().isEmpty)
    }
}
