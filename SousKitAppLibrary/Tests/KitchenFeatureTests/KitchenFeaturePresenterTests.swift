import Foundation
@testable import KitchenFeature
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
        KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepository = RecipeRepositorySpy()
    ) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: viewModel,
            parser: parser,
            restorationStore: KitchenRestorationStore(userDefaults: defaults.userDefaults),
            handler: handler,
            recipeRepository: recipeRepository
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
    @Test("the settings open over the recipe list")
    func settingsOpen() {
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didTapSettings()

        #expect(viewModel.openSettings?.isRestored == false)
    }

    @MainActor
    @Test("the settings do not open over a recipe")
    func settingsStayShutOverARecipe() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeEntry(named: "crepes"))])
        presenter.didTapSettings()

        #expect(viewModel.openSettings == nil)
    }

    @MainActor
    @Test("the settings close when they are done or dismissed")
    func settingsClose() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didTapSettings()
        presenter.settingsFeatureDidFinish()

        #expect(viewModel.openSettings == nil)

        presenter.didTapSettings()
        presenter.didDismissSettings()

        #expect(viewModel.openSettings == nil)
    }

    @MainActor
    @Test("a folder connected in the settings closes them and is reported once they are gone")
    func folderConnectedReports() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapSettings()
        presenter.settingsFeatureDidConnectRecipeRepository(RecipeRepositorySpy())

        #expect(viewModel.openSettings == nil)
        #expect(handler.connectCount == 0)

        // The sheet writes its closing back through the binding before it reports it finished.
        presenter.didDismissSettings()
        presenter.didFinishDismissingSettings()
        presenter.didFinishDismissingSettings()

        #expect(handler.connectCount == 1)
    }

    @MainActor
    @Test("another kind of repository picked in the settings closes them and is reported once they are gone")
    func pickingAKindReports() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(viewModel.openSettings == nil)
        #expect(handler.selectedRecipeRepositoryKinds.isEmpty)

        presenter.didFinishDismissingSettings()

        #expect(handler.selectedRecipeRepositoryKinds == [.mock])
    }

    @MainActor
    @Test("the kind of repository already read, picked in the settings, leaves them open and reports nothing")
    func pickingTheSameKindReportsNothing() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.files)
        presenter.didFinishDismissingSettings()

        #expect(viewModel.openSettings != nil)
        #expect(handler.selectedRecipeRepositoryKinds.isEmpty)
    }

    @MainActor
    @Test("a reset confirmed in the settings closes them and reports once they are gone")
    func confirmedResetReports() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapSettings()
        presenter.settingsFeatureDidConfirmReset()

        #expect(viewModel.openSettings == nil)
        #expect(handler.resetCount == 0)

        presenter.didFinishDismissingSettings()

        #expect(handler.resetCount == 1)
    }

    @MainActor
    @Test("settings closed with Done report nothing once they are gone")
    func doneReportsNothing() {
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didTapSettings()
        presenter.settingsFeatureDidFinish()
        presenter.didFinishDismissingSettings()

        #expect(handler.connectCount == 0)
        #expect(handler.selectedRecipeRepositoryKinds.isEmpty)
        #expect(handler.resetCount == 0)
    }

    @MainActor
    @Test("the settings do not open again while settings that replace the kitchen slide away")
    func settingsWaitForThePendingExit() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didTapSettings()
        presenter.settingsFeatureDidConfirmReset()
        presenter.didTapSettings()

        #expect(viewModel.openSettings == nil)

        presenter.didFinishDismissingSettings()
        presenter.didTapSettings()

        #expect(viewModel.openSettings != nil)
    }
}
