import CookingFeature
import Foundation
@testable import KitchenFeature
@testable import RecipeFeature
import RecipeLibrary
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
        let viewModel = KitchenFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .files
        )
        viewModel.isRestoring = isRestoring

        return viewModel
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        recipeRepository: RecipeRepositorySpy = RecipeRepositorySpy()
    ) -> KitchenFeaturePresenter {
        KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: TimerSchedulerStub()
            ),
            handler: KitchenFeatureHandlerStub(),
            recipeFeatureFactory: RecipeFeatureFactory(parser: parser, recipeRepository: recipeRepository),
            recipeRepository: recipeRepository,
            restorationSettleTime: .zero,
            restorationStore: restorationStore,
            timerScheduler: TimerSchedulerStub(),
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("a recipe pushed on the stack is kept for the next cold start")
    func pushKeepsTheRecipe() {
        makePresenter(viewModel: makeViewModel()).didChangeScreenPath([.recipe(crepes)])

        #expect(restorationStore.restoration() == KitchenRestoration(recipeID: crepes.id, isCooking: false))
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

        #expect(restorationStore.restoration()?.isCooking == true)

        presenter.cookingFeatureDidExit()

        #expect(restorationStore.restoration() == KitchenRestoration(recipeID: crepes.id, isCooking: false))
    }

    @MainActor
    @Test("cooking dismissed is forgotten")
    func dismissedCookingIsForgotten() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let presenter = makePresenter(viewModel: makeViewModel())

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.didDismissCooking()

        #expect(restorationStore.restoration()?.isCooking == false)
    }

    @MainActor
    @Test("a kitchen restored opens the recipe kept as the repository lists it now, with a feature to render it")
    func restoreOpensTheListedRecipe() async {
        let listedCrepes = RecipeEntry(
            id: crepes.id,
            name: crepes.name,
            availability: .downloaded
        )
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, isCooking: true))

        recipeRepository.send(.success([listedCrepes]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        #expect(viewModel.screenPath == [.recipe(listedCrepes)])
        #expect(viewModel.openRecipe?.recipeEntry == listedCrepes)
        #expect(viewModel.openCooking == nil)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration()?.isCooking == true)
    }

    @MainActor
    @Test("a kitchen whose recipe is no longer listed stays on its recipe list and forgets the recipe")
    func restoreWithoutTheRecipe() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, isCooking: true))

        recipeRepository.send(.success([]))
        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe == nil)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("a kitchen whose recipes cannot be listed stays on its recipe list and forgets the recipe")
    func restoreAfterAFailure() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, isCooking: false))

        recipeRepository.send(.failure(CocoaError(.fileReadNoSuchFile)))
        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

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
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, isCooking: false))

        recipeRepository.send(.success([crepes]))
        recipeRepository.send(.success([renamedCrepes]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("cooking resumed opens over the kitchen as resumed, and stays kept")
    func resumedCookingOpens() async {
        let recipe = parser.parseRecipe("Whisk it.").value
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, isCooking: true))

        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await presenter.viewDidAppear()
        presenter.recipeFeatureDidResumeCooking(recipe: recipe)

        #expect(viewModel.openCooking?.isResumed == true)
        #expect(restorationStore.restoration()?.isCooking == true)
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
            isCooking: true
        )

        restorationStore.save(restoration)

        #expect(restorationStore.restoration() == restoration)

        restorationStore.clear()

        #expect(restorationStore.restoration() == nil)
    }
}
