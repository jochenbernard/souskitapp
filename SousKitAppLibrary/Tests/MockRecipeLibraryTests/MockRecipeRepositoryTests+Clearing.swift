import Foundation
@testable import MockRecipeLibrary
import RecipeLibrary
import Testing

extension MockRecipeRepositoryTests {
    @MainActor
    @Test("clearing forgets the symbols picked, the recipes fetched and the files exported, the kept picks included")
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

        let crepes = try await currentRecipeEntry(withID: "crepes.sous", of: repository)
        _ = try await repository.readRecipe(of: crepes)
        _ = try await repository.exportRecipeFile(of: crepes)

        repository.clear()

        let listedRecipes = try await currentListedRecipes(of: repository)

        #expect(listedRecipes.allSatisfy({ $0.symbolPick == nil }))
        #expect(listedRecipes.first(where: { $0.entry.id == "crepes.sous" })?.entry.availability == .notDownloaded)
        #expect(MockSymbolCache(fileURL: symbolCacheURL).load().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: exportFolderURL.path(percentEncoded: false)))
    }
}
