@testable import KitchenFeature
import Observation
import os
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature card menus", .timeLimit(.minutes(1)))
struct KitchenFeatureMenuTests {
    let parser = SousParser()

    @MainActor
    private func makePresenter(viewModel: KitchenFeatureViewModel) -> KitchenFeaturePresenter {
        .stubbed(viewModel: viewModel, parser: parser)
    }

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    }

    /// Whether the action gives the view model a new value at the key path, rather than leaving it be.
    @MainActor
    private func replaces<Value>(
        _ keyPath: KeyPath<KitchenFeatureViewModel, Value>,
        in viewModel: KitchenFeatureViewModel,
        when action: () -> Void
    ) -> Bool {
        let isReplaced = OSAllocatedUnfairLock(initialState: false)

        withObservationTracking(
            { _ = viewModel[keyPath: keyPath] },
            onChange: { isReplaced.withLock({ $0 = true }) }
        )
        action()

        return isReplaced.withLock({ $0 })
    }

    @MainActor
    @Test("a recipe previewed gets a feature, off the stack")
    func previewBuildsAFeature() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didPreview(crepes)

        #expect(viewModel.previewedRecipe?.recipeEntry == crepes)
        #expect(viewModel.pushedScreens.isEmpty)
        #expect(viewModel.openRecipe == nil)
    }

    @MainActor
    @Test("a recipe previewed again keeps the feature that read it, and another recipe gets another")
    func previewingAgainKeepsTheFeature() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let brioche = RecipeEntry.stubbed(at: "Baking/brioche")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPreview(crepes)

        #expect(!replaces(\.previewedRecipe, in: viewModel) {
            presenter.didPreview(crepes)
        })
        #expect(replaces(\.previewedRecipe, in: viewModel) {
            presenter.didPreview(brioche)
        })
        #expect(viewModel.previewedRecipe?.recipeEntry == brioche)
    }

    @MainActor
    @Test("a recipe pushed from its card zooms out of that card, and a folder slides in")
    func recipePushZooms() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.folder(["Baking"]), from: nil)
        presenter.didPush(.recipe(crepes), from: .folder(["Baking"]))

        #expect(viewModel.zoomedRecipeIDs == [crepes.id])
    }

    @MainActor
    @Test("cooking chosen from a card pushes the recipe, and waits for it to be on display")
    func cookingWaitsForTheScreen() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChooseCooking(crepes, from: nil)

        #expect(viewModel.pushedScreens == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)

        presenter.screenDidAppear(.folder(["Baking"]))

        #expect(presenter.menuRequest.take(for: .recipe(crepes)) == .cooking)
    }

    @MainActor
    @Test("a screen on display takes what its card's menu asked of it, once")
    func appearanceTakesTheRequest() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChooseScaling(crepes, from: nil)
        presenter.screenDidAppear(.recipe(crepes))

        #expect(presenter.menuRequest.take(for: .recipe(crepes)) == nil)
    }

    @MainActor
    @Test("a screen popped before it is on display forgets what its card's menu asked of it")
    func popForgetsTheRequest() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChooseScaling(crepes, from: nil)
        presenter.didPop(toCount: 0)
        presenter.didPush(.recipe(crepes), from: nil)

        #expect(presenter.menuRequest.take(for: .recipe(crepes)) == nil)
    }

    @MainActor
    @Test("a menu choice while something is open over the kitchen pushes nothing and asks nothing")
    func coveredChoicePushesNothing() {
        let crepes = RecipeEntry.stubbed(at: "Baking/crepes")
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler
        )

        handler.kitchenFeatureIsCovered = true
        presenter.didChooseCooking(crepes, from: nil)

        #expect(viewModel.pushedScreens.isEmpty)
        #expect(presenter.menuRequest.take(for: .recipe(crepes)) == nil)
    }

    @MainActor
    @Test("searching chosen from a folder's card pushes the folder, and activates its search once it is on display")
    func searchWaitsForTheScreen() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChooseSearch(inFolderAt: ["Baking"], from: nil)

        #expect(viewModel.pushedScreens == [.folder(["Baking"])])
        #expect(viewModel.presentedSearchPath == nil)

        presenter.screenDidAppear(.folder(["Baking"]))

        #expect(viewModel.presentedSearchPath == ["Baking"])
    }

    @MainActor
    @Test("showing a found recipe's folder pushes the folder over the search")
    func showingTheFolderPushesIt() {
        let crepes = RecipeEntry.stubbed(at: "French/Classic/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.folder(["French"]), from: nil)
        presenter.didChooseFolder(of: crepes, from: .folder(["French"]))

        #expect(viewModel.pushedScreens == [.folder(["French"]), .folder(["French", "Classic"])])
        #expect(viewModel.zoomedRecipeIDs.isEmpty)
    }

    @MainActor
    @Test("showing a found recipe's folder ends the search it was found in")
    func showingTheFolderEndsTheSearch() {
        let crepes = RecipeEntry.stubbed(at: "French/Classic/crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didPush(.folder(["French"]), from: nil)
        presenter.didChangeIsSearchPresented(true, in: ["French"])
        presenter.didChooseFolder(of: crepes, from: .folder(["French"]))

        #expect(viewModel.presentedSearchPath == nil)
        #expect(viewModel.pushedScreens == [.folder(["French"]), .folder(["French", "Classic"])])
    }
}
