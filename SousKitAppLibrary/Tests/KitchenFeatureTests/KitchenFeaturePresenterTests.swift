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

    /// An entry named after its file, with the header `header` already read.
    private func recipeEntry(id: String, header: String) -> RecipeEntry {
        RecipeEntry(
            id: id,
            name: id.replacing("-", with: " "),
            availability: .downloaded,
            summary: RecipeSummary(recipe: parser.parseRecipe(header).value, parser: parser)
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

    /// The cards the view model holds once the repository lists `recipeEntries` and ends.
    @MainActor
    private func cards(listing recipeEntries: [RecipeEntry]) async -> [KitchenRecipeCard] {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()

        recipeRepository.send(.success(recipeEntries))
        recipeRepository.finish()
        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).viewDidAppear()

        guard case .recipes(let folder) = viewModel.recipeList else {
            Issue.record("The recipe list did not list recipes.")
            return []
        }

        return folder.cards
    }

    /// Whether the view model reaches the given names in the folder at the path, the top by default, waiting until it
    /// does or the suite's time limit ends the test.
    @MainActor
    private func names(
        reach expected: [String],
        in viewModel: KitchenFeatureViewModel,
        at path: [String] = []
    ) async -> Bool {
        while !Task.isCancelled {
            if
                case .recipes(let folder) = viewModel.recipeList,
                folder.folder(at: path)?.cards.map(\.recipeEntry.name) == expected
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
        let cards = await cards(listing: [recipeEntry(named: "boeuf bourguignon"), recipeEntry(named: "crepes")])

        #expect(cards.map(\.recipeEntry.name) == ["boeuf bourguignon", "crepes"])
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
    @Test("the recipes are listed by the title their rows show, the name where the header gives none")
    func sortedByTitle() async {
        let cards = await cards(listing: [
            recipeEntry(id: "a-gratin", header: "---\ntitle: Gratin Dauphinois\n---"),
            recipeEntry(id: "boeuf-bourguignon", header: "---\ntitle: Boeuf Bourguignon\n---"),
            recipeEntry(id: "crepes", header: "Whisk @{200 g} flour@."),
            recipeEntry(id: "zz-brioche", header: "---\ntitle: Brioche\n---")
        ])

        #expect(cards.map(\.recipeEntry.title) == ["Boeuf Bourguignon", "Brioche", "crepes", "Gratin Dauphinois"])
    }

    @MainActor
    @Test("recipes sharing a title are listed in the order of their ids")
    func sharedTitles() async {
        let cards = await cards(listing: [
            recipeEntry(id: "vinaigrette-2", header: "---\ntitle: Vinaigrette\n---"),
            recipeEntry(id: "header-only", header: "---\ntitle: Vinaigrette\n---"),
            recipeEntry(id: "vinaigrette", header: "---\ntitle: Vinaigrette\n---")
        ])

        #expect(cards.map(\.id) == ["header-only", "vinaigrette", "vinaigrette-2"])
    }

    @MainActor
    @Test("a card shows the total time its recipe's header gives, and none where it gives none")
    func cardTimes() async {
        let cards = await cards(listing: [
            recipeEntry(
                id: "boeuf-bourguignon",
                header: "---\ntitle: Boeuf Bourguignon\nprep-time: 30 min\ncook-time: 3 h\n---"
            ),
            recipeEntry(id: "crepes", header: "Whisk @{200 g} flour@."),
            recipeEntry(named: "unreachable")
        ])

        #expect(cards.map(\.recipeEntry.summary?.totalTime) == [.duration(.seconds(12_600.0)), nil, nil])
    }

    @MainActor
    @Test("a card's placeholder takes the color its title hashes to and the default symbol")
    func cardPlaceholders() async {
        let cards = await cards(listing: [
            recipeEntry(id: "crepes", header: "---\ntitle: Crepes\n---"),
            recipeEntry(id: "header-only", header: "---\ntitle: Vinaigrette\n---"),
            recipeEntry(id: "vinaigrette", header: "---\ntitle: Vinaigrette\n---")
        ])

        let colors = ["Crepes", "Vinaigrette", "Vinaigrette"].map(PlaceholderColorPick.color(forTitle:))

        #expect(cards.map(\.placeholderColor) == colors)
        #expect(cards.map(\.placeholderSymbol) == ["fork.knife", "fork.knife", "fork.knife"])
    }

    @MainActor
    @Test("a recipe the repository lists later in a folder reaches that folder")
    func addedRecipeInAFolderReachesIt() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        let task = Task {
            await presenter.viewDidAppear()
        }
        defer {
            task.cancel()
        }
        let brioche = RecipeEntry(
            id: "Baking/brioche.sous",
            name: "brioche",
            availability: .downloaded,
            folderPath: ["Baking"]
        )
        let madeleines = RecipeEntry(
            id: "Baking/madeleines.sous",
            name: "madeleines",
            availability: .downloaded,
            folderPath: ["Baking"]
        )

        recipeRepository.send(.success([brioche]))
        recipeRepository.send(.success([brioche, madeleines]))

        #expect(await names(reach: ["brioche", "madeleines"], in: viewModel, at: ["Baking"]))

        guard case .recipes(let folder) = viewModel.recipeList else {
            Issue.record("The recipe list did not list recipes.")
            return
        }

        #expect(folder.cards.isEmpty)
        #expect(folder.folders.map(\.name) == ["Baking"])
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
