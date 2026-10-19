@testable import KitchenFeature
import RecipeLibrary
import Testing

extension KitchenFeatureRestorationTests {
    @MainActor
    @Test("a kitchen restored on a recipe a search opened pushes it over the top list, with nothing searched for")
    func restoreARecipeOpenedFromASearch() async {
        let bourguignon = RecipeEntry.stubbed(at: "French/Classic/boeuf-bourguignon")
        let restoration = KitchenFeatureRestoration(recipeID: bourguignon.id)

        let kitchen = await restore(restoration, listing: [.success([.stubbed(at: "crepes"), bourguignon])])

        #expect(kitchen.viewModel.pushedScreens == [.recipe(bourguignon)])
        #expect(kitchen.viewModel.openRecipe?.recipeEntry == bourguignon)
        #expect(kitchen.viewModel.searchText.isEmpty)
        #expect(kitchen.viewModel.search == .idle)
        #expect(kitchen.handler.restoration == restoration)
    }

    @MainActor
    @Test("a kitchen restored on a recipe in a folder outside the one pushed leaves the recipe out")
    func restoreNoRecipeOutsideItsFolder() async {
        let bourguignon = RecipeEntry.stubbed(at: "French/Classic/boeuf-bourguignon")

        let kitchen = await restore(
            KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: bourguignon.id),
            listing: [.success([.stubbed(at: "Baking/brioche"), bourguignon])]
        )

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
    }
}
