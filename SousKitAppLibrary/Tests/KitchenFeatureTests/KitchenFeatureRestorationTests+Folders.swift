@testable import CookingFeature
@testable import KitchenFeature
import RecipeLibrary
import Testing

extension KitchenFeatureRestorationTests {
    @MainActor
    @Test("a kitchen restored pushes every folder down the path, then the recipe on top")
    func restoreOpensThePath() async {
        let gratin = RecipeEntry.stubbed(at: "French/Comfort food/gratin-dauphinois")
        let restoration = KitchenFeatureRestoration(folderPath: ["French", "Comfort food"], recipeID: gratin.id)

        let kitchen = await restore(restoration, listing: [.success([.stubbed(at: "crepes"), gratin])])

        #expect(
            kitchen.viewModel.pushedScreens == [
                .folder(["French"]),
                .folder(["French", "Comfort food"]),
                .recipe(gratin)
            ]
        )
        #expect(kitchen.viewModel.openRecipe?.recipeEntry == gratin)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == restoration)
    }

    @MainActor
    @Test("a kitchen restored on a folder with no recipe over it pushes the folders alone")
    func restoreOpensFolders() async {
        let restoration = KitchenFeatureRestoration(folderPath: ["Baking"])

        let kitchen = await restore(restoration, listing: [.success([.stubbed(at: "Baking/brioche")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(kitchen.viewModel.openRecipe == nil)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == restoration)
    }

    @MainActor
    @Test("a kitchen restored opens the recipe of its path, not one sharing its file name in another folder")
    func restoreOpensTheRecipeOfItsFolder() async {
        let top = RecipeEntry.stubbed(at: "vinaigrette")
        let nested = RecipeEntry.stubbed(at: "Sauce/vinaigrette")

        let kitchen = await restore(
            KitchenFeatureRestoration(folderPath: ["Sauce"], recipeID: nested.id),
            listing: [.success([top, nested])]
        )

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Sauce"]), .recipe(nested)])
    }

    @MainActor
    @Test("a kitchen whose deeper folders are gone pushes the folders still listed, and reports only those")
    func restoreWithoutTheDeeperFolders() async {
        let restoration = KitchenFeatureRestoration(
            folderPath: ["French", "Comfort food"],
            recipeID: "French/Comfort food/gratin-dauphinois",
            cooking: CookingFeatureRestoration()
        )

        let kitchen = await restore(restoration, listing: [.success([.stubbed(at: "French/Classic/quiche-lorraine")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["French"])])
        #expect(kitchen.viewModel.openRecipe == nil)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(folderPath: ["French"]))
    }

    @MainActor
    @Test("a kitchen whose recipe is gone from its folder pushes the folders, and reports no recipe")
    func restoreWithoutTheRecipeInItsFolder() async {
        let restoration = KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: "Baking/brioche")

        let kitchen = await restore(restoration, listing: [.success([.stubbed(at: "Baking/madeleines")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(folderPath: ["Baking"]))
    }

    @MainActor
    @Test("a kitchen whose first folder is gone stays on its recipe list and reports nothing open")
    func restoreWithoutAnyFolder() async {
        let kitchen = await restore(
            KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: "Baking/brioche"),
            listing: [.success([.stubbed(at: "crepes")])]
        )

        #expect(kitchen.viewModel.pushedScreens.isEmpty)
        #expect(kitchen.handler.restoreCount == 0)
        #expect(kitchen.handler.restoration == nil)
    }
}
