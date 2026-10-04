import CookingFeature
import Foundation
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature presenter", .timeLimit(.minutes(1)))
struct KitchenFeaturePresenterTests {
    private let parser = SousParser()
    private let defaults: ThrowawayDefaults

    @MainActor
    init() throws {
        self.defaults = try ThrowawayDefaults()
    }

    private func recipeEntry(named name: String) -> RecipeEntry {
        RecipeEntry(
            id: name,
            name: name,
            availability: .downloaded
        )
    }

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .files
        )
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepository = RecipeRepositorySpy()
    ) -> KitchenFeaturePresenter {
        KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: TimerSchedulerStub()
            ),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(parser: parser, recipeRepository: recipeRepository),
            recipeRepository: recipeRepository,
            restorationSettleTime: .zero,
            restorationStore: KitchenRestorationStore(userDefaults: defaults.userDefaults),
            timerScheduler: TimerSchedulerStub(),
            viewModel: viewModel
        )
    }

    /// Whether the view model reaches the given names, waiting until it does or the suite's time
    /// limit ends the test.
    @MainActor
    private func names(reach expected: [String], in viewModel: KitchenFeatureViewModel) async -> Bool {
        while !Task.isCancelled {
            if
                case .recipes(let recipeEntries) = viewModel.recipeList,
                recipeEntries.map(\.name) == expected
            {
                return true
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        return false
    }

    @MainActor
    @Test("the view model starts out reading")
    func readingBeforeTheFirstRead() {
        guard case .reading = makeViewModel().recipeList else {
            Issue.record("The recipe list did not start out reading.")
            return
        }
    }

    @MainActor
    @Test("the recipes the repository lists reach the view model")
    func recipesReachTheViewModel() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.success([recipeEntry(named: "boeuf bourguignon"), recipeEntry(named: "crepes")]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        guard case .recipes(let recipeEntries) = viewModel.recipeList else {
            Issue.record("The recipe list did not list recipes.")
            return
        }

        #expect(recipeEntries.map(\.name) == ["boeuf bourguignon", "crepes"])
    }

    @MainActor
    @Test("a recipe the repository lists later reaches the view model")
    func addedRecipeReachesTheViewModel() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        let task = Task {
            await presenter.viewDidAppear()
        }
        defer {
            task.cancel()
        }

        recipeRepository.send(.success([recipeEntry(named: "crepes")]))

        #expect(await names(reach: ["crepes"], in: viewModel))

        recipeRepository.send(.success([recipeEntry(named: "brioche"), recipeEntry(named: "crepes")]))

        #expect(await names(reach: ["brioche", "crepes"], in: viewModel))
    }

    @MainActor
    @Test("a failed read reaches the view model as a failure")
    func failureReachesTheViewModel() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.failure(CocoaError(.fileReadNoSuchFile)))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        guard case .failure(let message) = viewModel.recipeList else {
            Issue.record("The recipe list did not fail.")
            return
        }

        #expect(!message.isEmpty)
    }

    @MainActor
    @Test("coming back to the foreground refreshes the repository")
    func becomingActiveRefreshes() async {
        let recipeRepository = RecipeRepositorySpy()

        await makePresenter(viewModel: makeViewModel(), recipeRepository: recipeRepository).didBecomeActive()

        #expect(recipeRepository.refreshCount == 1)
    }

    @MainActor
    @Test("picking a kind of repository reports it")
    func pickingAKindReports() {
        let handler = KitchenFeatureHandlerStub()

        makePresenter(viewModel: makeViewModel(), handler: handler).didSelectRecipeRepositoryKind(.mock)

        #expect(handler.selectedRecipeRepositoryKinds == [.mock])
    }

    @MainActor
    @Test("the reset opens the confirmation and reports nothing yet")
    func resetOpensTheConfirmation() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel, handler: handler).didTapReset()

        #expect(viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)
    }

    @MainActor
    @Test("a confirmed reset closes the confirmation and reports once")
    func confirmedResetReports() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapReset()
        presenter.didConfirmReset()

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 1)
    }

    @MainActor
    @Test("a dismissed confirmation reports nothing")
    func dismissedConfirmationReportsNothing() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapReset()
        presenter.didChangeIsConfirmingReset(false)

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)
    }
}
