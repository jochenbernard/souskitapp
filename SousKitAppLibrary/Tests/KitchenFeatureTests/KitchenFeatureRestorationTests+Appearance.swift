@testable import KitchenFeature
import RecipeLibrary
import Testing

extension KitchenFeatureRestorationTests {
    @MainActor
    @Test("a kitchen restored pushes nothing until its own screen has appeared")
    func restoreWaitsForTheTopScreen() async {
        let crepes = RecipeEntry.stubbed(at: "crepes")

        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id),
            listing: [.success([crepes])],
            topScreenAppearing: false,
            appearing: false
        )

        #expect(kitchen.viewModel.pushedScreens.isEmpty)
        #expect(kitchen.viewModel.isRestoring)

        kitchen.presenter.screenDidAppear(nil)

        #expect(kitchen.viewModel.pushedScreens == [.recipe(crepes)])
        #expect(kitchen.viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("a kitchen restored slides its recipe in, and is restored once the recipe has appeared")
    func restoreEndsOnceTheRecipeHasAppeared() async {
        let crepes = RecipeEntry.stubbed(at: "crepes")

        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id),
            listing: [.success([crepes])],
            appearing: false
        )
        let feature = KitchenFeature(presenter: kitchen.presenter, viewModel: kitchen.viewModel)

        #expect(kitchen.viewModel.pushedScreens == [.recipe(crepes)])
        #expect(feature.isRestoring)
        #expect(!feature.pushesWithoutAnimation)
        #expect(kitchen.handler.restoreCount == 0)

        kitchen.presenter.screenDidAppear(.recipe(crepes))

        #expect(!feature.isRestoring)
        #expect(kitchen.handler.restoreCount == 1)
    }

    @MainActor
    @Test("a kitchen restored pushes the folders on the way without animating")
    func restorePushesFoldersWithoutAnimating() async {
        let brioche = RecipeEntry.stubbed(at: "Baking/brioche")

        let kitchen = await restore(
            KitchenFeatureRestoration(folderPath: ["Baking"], recipeID: brioche.id),
            listing: [.success([brioche])],
            appearing: false
        )
        let feature = KitchenFeature(presenter: kitchen.presenter, viewModel: kitchen.viewModel)

        #expect(kitchen.viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(feature.pushesWithoutAnimation)
    }
}
