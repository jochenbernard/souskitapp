@testable import KitchenFeature
import RecipeLibrary
import SwiftUI
import Testing

extension KitchenFeatureStackTests {
    @MainActor
    @Test("a folder pushed from the top, then one inside it, then a recipe in that, stack in that order")
    func pushingDownFolders() {
        let brioche = recipeEntry(named: "Baking/Classic/brioche")
        let viewModel = makeViewModel()
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPush(.folder(["Baking", "Classic"]), from: .folder(["Baking"]))
        presenter.didPush(.recipe(brioche), from: .folder(["Baking", "Classic"]))

        #expect(
            viewModel.pushedScreens == [.folder(["Baking"]), .folder(["Baking", "Classic"]), .recipe(brioche)]
        )
        #expect(viewModel.openRecipe?.recipeEntry == brioche)
        #expect(
            handler.restoration == KitchenFeatureRestoration(folderPath: ["Baking", "Classic"], recipeID: brioche.id)
        )
    }

    @MainActor
    @Test("a row pressed on a screen under the top pushes over that screen, not over the top")
    func pushingFromAScreenUnderTheTop() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPush(.folder(["Baking", "Classic"]), from: .folder(["Baking"]))
        presenter.didPush(.folder(["Baking", "Classic"]), from: .folder(["Baking"]))

        #expect(viewModel.pushedScreens == [.folder(["Baking"]), .folder(["Baking", "Classic"])])
    }

    @MainActor
    @Test("a row pressed on a screen no longer on the stack pushes nothing")
    func pushingFromAPoppedScreen() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPop(toCount: 0)
        presenter.didPush(.recipe(recipeEntry(named: "Baking/brioche")), from: .folder(["Baking"]))

        #expect(viewModel.pushedScreens.isEmpty)
    }

    @MainActor
    @Test("popping several screens at once leaves those under them, and reports the folder left on top")
    func poppingSeveralScreens() {
        let viewModel = makeViewModel()
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPush(.folder(["Baking", "Classic"]), from: .folder(["Baking"]))
        presenter.didPush(
            .recipe(recipeEntry(named: "Baking/Classic/brioche")),
            from: .folder(["Baking", "Classic"])
        )
        presenter.didPop(toCount: 1)

        #expect(viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(handler.restoration == KitchenFeatureRestoration(folderPath: ["Baking"]))
    }

    @MainActor
    @Test("popping back to the top from a folder reports nothing open")
    func poppingAFolder() {
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPop(toCount: 0)

        #expect(handler.restoration == nil)
    }

    @MainActor
    @Test("recipes sharing a file name in two folders open as two recipes")
    func sameFileNameInTwoFolders() {
        let top = recipeEntry(named: "vinaigrette")
        let nested = recipeEntry(named: "Sauce/vinaigrette")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.recipe(top), from: nil)
        presenter.didPop(toCount: 0)
        presenter.didPush(.folder(["Sauce"]), from: nil)
        presenter.didPush(.recipe(nested), from: .folder(["Sauce"]))

        #expect(viewModel.openRecipe?.recipeEntry == nested)
    }

    @MainActor
    @Test("the stack's path holds every screen pushed")
    func pathHoldsEveryScreen() {
        let brioche = recipeEntry(named: "Baking/brioche")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let feature = KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPush(.recipe(brioche), from: .folder(["Baking"]))

        #expect(feature.path.wrappedValue == NavigationPath([KitchenScreen.folder(["Baking"]), .recipe(brioche)]))

        feature.path.wrappedValue.removeLast()

        #expect(viewModel.pushedScreens == [.folder(["Baking"])])
    }

    @MainActor
    @Test("the stack's path holds the pushed recipe, and holds nothing on the list")
    func pathHoldsThePushedRecipe() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let feature = KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )

        #expect(feature.path.wrappedValue.isEmpty)

        presenter.didPush(.recipe(crepes), from: nil)

        #expect(feature.path.wrappedValue == NavigationPath([KitchenScreen.recipe(crepes)]))
    }

    @MainActor
    @Test("the stack popping its path pops the recipe")
    func poppingThePathPopsTheRecipe() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let feature = KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )

        presenter.didPush(.recipe(crepes), from: nil)
        feature.path.wrappedValue = NavigationPath()

        #expect(viewModel.pushedScreens.isEmpty)
    }
}
