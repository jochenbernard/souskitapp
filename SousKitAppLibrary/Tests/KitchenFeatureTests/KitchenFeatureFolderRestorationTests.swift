@testable import CookingFeature
@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature restoration of folders", .timeLimit(.minutes(1)))
struct KitchenFeatureFolderRestorationTests {
    /// A kitchen built to open a restoration again, with what it reported.
    private struct RestoredKitchen {
        let viewModel: KitchenFeatureViewModel
        let handler: KitchenFeatureHandlerStub
    }

    private let parser = SousParser()

    /// Builds a kitchen to open the restoration again, whose repository lists each of the results in turn.
    @MainActor
    private func restore(
        _ restoration: KitchenFeatureRestoration,
        listing results: [Result<[RecipeEntry], Error>]
    ) async -> RestoredKitchen {
        let handler = KitchenFeatureHandlerStub(restoration: restoration)
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        viewModel.isRestoring = true
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            recipeRepository: recipeRepository,
            restoration: restoration
        )

        for result in results {
            recipeRepository.send(result)
        }

        recipeRepository.finish()
        await presenter.viewDidAppear()

        return RestoredKitchen(viewModel: viewModel, handler: handler)
    }

    /// A recipe sitting in the folders of its path, named after its file.
    private func recipeEntry(_ path: String) -> RecipeEntry {
        let components = path.split(separator: "/").map(String.init)

        return RecipeEntry(
            id: path,
            name: components.last ?? path,
            availability: .downloaded,
            folderPath: Array(components.dropLast())
        )
    }

    @MainActor
    @Test("a kitchen restored pushes every folder down the path, then the recipe on top")
    func restoreOpensThePath() async {
        let gratin = recipeEntry("French/Comfort food/gratin-dauphinois")
        let restoration = KitchenFeatureRestoration(folderPath: ["French", "Comfort food"], recipeID: gratin.id)

        let kitchen = await restore(restoration, listing: [.success([recipeEntry("crepes"), gratin])])

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

        let kitchen = await restore(restoration, listing: [.success([recipeEntry("Baking/brioche")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(kitchen.viewModel.openRecipe == nil)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == restoration)
    }

    @MainActor
    @Test("a kitchen restored opens the recipe of its path, not one sharing its file name in another folder")
    func restoreOpensTheRecipeOfItsFolder() async {
        let top = recipeEntry("vinaigrette")
        let nested = recipeEntry("Sauce/vinaigrette")

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

        let kitchen = await restore(restoration, listing: [.success([recipeEntry("French/Classic/quiche-lorraine")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["French"])])
        #expect(kitchen.viewModel.openRecipe == nil)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(folderPath: ["French"]))
    }

    @MainActor
    @Test("a kitchen whose recipe is gone from its folder pushes the folders, and reports no recipe")
    func restoreWithoutTheRecipeInItsFolder() async {
        let restoration = KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: "Baking/brioche")

        let kitchen = await restore(restoration, listing: [.success([recipeEntry("Baking/madeleines")])])

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(folderPath: ["Baking"]))
    }

    @MainActor
    @Test("a kitchen whose first folder is gone stays on its recipe list and reports nothing open")
    func restoreWithoutAnyFolder() async {
        let kitchen = await restore(
            KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: "Baking/brioche"),
            listing: [.success([recipeEntry("crepes")])]
        )

        #expect(kitchen.viewModel.pushedScreens.isEmpty)
        #expect(kitchen.handler.restoreCount == 0)
        #expect(kitchen.handler.restoration == nil)
    }
}
