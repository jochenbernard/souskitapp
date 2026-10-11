@testable import CookingFeature
import Foundation
@testable import KitchenFeature
@testable import RecipeFeature
import RecipeLibrary
import RecipeScaling
import SousKit
import Testing

@Suite("Kitchen feature restoration", .timeLimit(.minutes(1)))
struct KitchenFeatureRestorationTests {
    private let parser = SousParser()
    private let defaults: ThrowawayDefaults

    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .notDownloaded
    )

    @MainActor
    private var restorationStore: KitchenRestorationStore {
        KitchenRestorationStore(userDefaults: defaults.userDefaults)
    }

    @MainActor
    init() throws {
        self.defaults = try ThrowawayDefaults()
    }

    @MainActor
    private func makeViewModel(isRestoring: Bool = false) -> KitchenFeatureViewModel {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        viewModel.isRestoring = isRestoring

        return viewModel
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepositorySpy = RecipeRepositorySpy()
    ) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: viewModel,
            parser: parser,
            restorationStore: restorationStore,
            handler: handler,
            recipeRepository: recipeRepository
        )
    }

    /// Restores a kitchen whose repository lists each of the results in turn, and returns its view model and presenter.
    @MainActor
    private func restore(
        listing results: [Result<[RecipeEntry], Error>],
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub()
    ) async -> (viewModel: KitchenFeatureViewModel, presenter: KitchenFeaturePresenter) {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            recipeRepository: recipeRepository
        )

        for result in results {
            recipeRepository.send(result)
        }

        recipeRepository.finish()
        await presenter.viewDidAppear()

        return (viewModel, presenter)
    }

    @MainActor
    @Test("a recipe pushed on the stack is kept for the next cold start")
    func pushKeepsTheRecipe() {
        makePresenter(viewModel: makeViewModel()).didChangeScreenPath([.recipe(crepes)])

        #expect(restorationStore.restoration() == KitchenRestoration(recipeID: crepes.id))
    }

    @MainActor
    @Test("popping back to the recipe list forgets the recipe")
    func popForgetsTheRecipe() {
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.didChangeScreenPath([])

        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("what the recipe screen reports is kept beside the recipe")
    func recipeReportIsKept() {
        let restoration = RecipeFeatureRestoration(
            scale: RecipeScale(target: .multiplier, value: 2.0),
            isScaling: true
        )
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidChangeRestoration(restoration)

        #expect(restorationStore.restoration()?.recipe == restoration)
    }

    @MainActor
    @Test("a report with no recipe on the stack keeps nothing")
    func reportWithoutARecipeKeepsNothing() {
        makePresenter(viewModel: makeViewModel()).recipeFeatureDidChangeRestoration(
            RecipeFeatureRestoration(scale: nil, isScaling: true)
        )

        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("cooking is kept while it is open, and forgotten once it is exited")
    func cookingIsKeptUntilExited() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(restorationStore.restoration()?.cooking == CookingFeatureRestoration())

        presenter.cookingFeatureDidExit()

        #expect(restorationStore.restoration() == KitchenRestoration(recipeID: crepes.id))
    }

    @MainActor
    @Test("cooking dismissed is forgotten")
    func dismissedCookingIsForgotten() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.didDismissCooking()

        #expect(restorationStore.restoration()?.cooking == nil)
    }

    @MainActor
    @Test("the steps cooking ticks off are kept, and forgotten once cooking is exited")
    func tickedStepsAreKeptUntilExited() {
        let cooking = CookingFeatureRestoration(completedStepNumbers: [1])
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: parser.parseRecipe("Whisk it.").value)
        presenter.cookingFeatureDidChangeRestoration(cooking)

        #expect(restorationStore.restoration()?.cooking == cooking)

        presenter.cookingFeatureDidExit()

        #expect(restorationStore.restoration()?.cooking == nil)
    }

    @MainActor
    @Test("a kitchen restored opens the recipe kept as the repository lists it now, with a feature to render it")
    func restoreOpensTheListedRecipe() async {
        let listedCrepes = RecipeEntry(
            id: crepes.id,
            name: crepes.name,
            availability: .downloaded
        )
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))

        let viewModel = await restore(listing: [.success([listedCrepes])]).viewModel

        #expect(viewModel.screenPath == [.recipe(listedCrepes)])
        #expect(viewModel.openRecipe?.recipeEntry == listedCrepes)
        #expect(viewModel.openCooking == nil)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration()?.cooking != nil)
    }

    @MainActor
    @Test("a kitchen restored reports the settings kept as restored, and keeps them")
    func restoreReportsTheSettings() async {
        let handler = KitchenFeatureHandlerStub()
        restorationStore.saveSettings()

        let viewModel = await restore(listing: [.success([crepes])], handler: handler).viewModel

        #expect(handler.settingsRestoreCount == 1)
        #expect(handler.settingsTapCount == 0)
        #expect(viewModel.screenPath.isEmpty)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration()?.isShowingSettings == true)
    }

    @MainActor
    @Test("a kitchen whose recipe is no longer listed stays on its recipe list and forgets the recipe")
    func restoreWithoutTheRecipe() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))

        let viewModel = await restore(listing: [.success([]), .success([crepes])]).viewModel

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe == nil)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("a kitchen whose recipes cannot be listed stays on its recipe list and forgets the recipe")
    func restoreAfterAFailure() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))

        let (viewModel, _) = await restore(listing: [.failure(CocoaError(.fileReadNoSuchFile)), .success([crepes])])

        #expect(viewModel.screenPath.isEmpty)
        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("a kitchen with nothing kept stays on its recipe list")
    func restoreWithNothingKept() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe == nil)
    }

    @MainActor
    @Test("a list arriving while the restored recipe is open leaves it open as it is")
    func laterListKeepsTheRestoredRecipe() async {
        let renamedCrepes = RecipeEntry(
            id: crepes.id,
            name: "crepes suzette",
            availability: crepes.availability
        )
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))

        let viewModel = await restore(listing: [.success([crepes]), .success([renamedCrepes])]).viewModel

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("cooking resumed opens over the kitchen as resumed, and stays kept")
    func resumedCookingOpens() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))

        let (viewModel, presenter) = await restore(listing: [.success([crepes])])
        presenter.recipeFeatureDidResumeCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(viewModel.openCooking?.isResumed == true)
        #expect(restorationStore.restoration()?.cooking != nil)
    }

    @MainActor
    @Test("cooking resumed keeps the steps it had ticked off")
    func resumedCookingKeepsItsTickedSteps() async {
        let cooking = CookingFeatureRestoration(completedStepNumbers: [1])
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: cooking))

        let presenter = await restore(listing: [.success([crepes])]).presenter
        presenter.recipeFeatureDidResumeCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(restorationStore.restoration()?.cooking == cooking)
    }

    @MainActor
    @Test("cooking started from the button opens as started, not resumed")
    func startedCookingIsNotResumed() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(viewModel.openCooking?.isResumed == false)
    }

    @MainActor
    @Test("the store keeps what it is given across instances, and nothing once cleared")
    func storeRoundTrip() {
        let restoration = KitchenRestoration(
            recipeID: crepes.id,
            recipe: RecipeFeatureRestoration(
                scale: RecipeScale(target: .yield(unit: "crepes"), value: 24.0),
                isScaling: false
            ),
            cooking: CookingFeatureRestoration(completedStepNumbers: [1, 3])
        )

        restorationStore.save(restoration)

        #expect(restorationStore.restoration() == restoration)

        restorationStore.clear()

        #expect(restorationStore.restoration() == nil)
    }
}
