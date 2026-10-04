import CookingFeature
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

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .files
        )
    }

    @MainActor
    private func makePresenter(viewModel: KitchenFeatureViewModel) -> KitchenFeaturePresenter {
        let recipeRepository = RecipeRepositorySpy()

        return KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: TimerSchedulerStub()
            ),
            handler: KitchenFeatureHandlerStub(),
            recipeFeatureFactory: RecipeFeatureFactory(parser: parser, recipeRepository: recipeRepository),
            recipeRepository: recipeRepository,
            restorationStore: restorationStore,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("a recipe pushed on the stack is kept for the next cold start")
    func pushKeepsTheRecipe() {
        makePresenter(viewModel: makeViewModel()).didChangeScreenPath([.recipe(crepes)])

        #expect(restorationStore.restoration() == KitchenRestoration(recipeEntry: crepes, isCooking: false))
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

        #expect(restorationStore.restoration() == KitchenRestoration(recipeEntry: crepes, isCooking: false))
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
    @Test("a kitchen restored opens the recipe kept, with a feature to render it")
    func restoreOpensTheRecipe() {
        restorationStore.save(KitchenRestoration(recipeEntry: crepes, isCooking: true))
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).restore()

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
        #expect(viewModel.openCooking == nil)
    }

    @MainActor
    @Test("a kitchen with nothing kept stays on its recipe list")
    func restoreWithNothingKept() {
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).restore()

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe == nil)
    }

    @MainActor
    @Test("cooking resumed opens over the kitchen as resumed, and stays kept")
    func resumedCookingOpens() {
        let recipe = parser.parseRecipe("Whisk it.").value
        restorationStore.save(KitchenRestoration(recipeEntry: crepes, isCooking: true))
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.restore()
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
            recipeEntry: crepes,
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
