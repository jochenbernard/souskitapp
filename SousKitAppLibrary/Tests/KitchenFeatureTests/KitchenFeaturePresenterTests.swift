import Foundation
@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature presenter", .timeLimit(.minutes(1)))
struct KitchenFeaturePresenterTests {
    private let parser = SousParser()

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

    /// An entry named after its file, with the header `header` already read.
    private func recipeEntry(id: String, header: String) -> RecipeEntry {
        RecipeEntry(
            id: id,
            name: id.replacing("-", with: " "),
            availability: .downloaded,
            summary: RecipeSummary(recipe: parser.parseRecipe(header).value)
        )
    }

    @MainActor
    @Test("the recipes are listed by the title their rows show, the name where the header gives none")
    func sortedByTitle() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.success([
            recipeEntry(id: "a-gratin", header: "---\ntitle: Gratin Dauphinois\n---"),
            recipeEntry(id: "boeuf-bourguignon", header: "---\ntitle: Boeuf Bourguignon\n---"),
            recipeEntry(id: "crepes", header: "Whisk @{200 g} flour@."),
            recipeEntry(id: "zz-brioche", header: "---\ntitle: Brioche\n---")
        ]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        guard case .recipes(let recipeEntries) = viewModel.recipeList else {
            Issue.record("The recipe list did not list recipes.")
            return
        }

        #expect(recipeEntries.map(\.title) == ["Boeuf Bourguignon", "Brioche", "crepes", "Gratin Dauphinois"])
    }

    @MainActor
    @Test("recipes sharing a title are listed in the order of their ids")
    func sharedTitles() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.success([
            recipeEntry(id: "vinaigrette-2", header: "---\ntitle: Vinaigrette\n---"),
            recipeEntry(id: "header-only", header: "---\ntitle: Vinaigrette\n---"),
            recipeEntry(id: "vinaigrette", header: "---\ntitle: Vinaigrette\n---")
        ]))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        guard case .recipes(let recipeEntries) = viewModel.recipeList else {
            Issue.record("The recipe list did not list recipes.")
            return
        }

        #expect(recipeEntries.map(\.id) == ["header-only", "vinaigrette", "vinaigrette-2"])
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
}
