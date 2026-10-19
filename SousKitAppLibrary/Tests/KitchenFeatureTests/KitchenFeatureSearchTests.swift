@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature search", .timeLimit(.minutes(1)))
struct KitchenFeatureSearchTests {
    /// A kitchen whose repository listed its recipes once.
    struct ListedKitchen {
        let viewModel: KitchenFeatureViewModel
        let presenter: KitchenFeaturePresenter
        let recipeRepository: RecipeRepositorySpy
        let handler: KitchenFeatureHandlerStub
    }

    private let parser = SousParser()

    private let bourguignon = ListedRecipe(
        entry: .stubbed(at: "French/Classic/boeuf-bourguignon"),
        ingredientNames: ["beef", "lardons", "red wine"]
    )

    private let quiche = ListedRecipe(
        entry: .stubbed(at: "quiche-lorraine"),
        ingredientNames: ["flour", "lardons", "cream"]
    )

    /// A search finding the recipes, in the order given.
    private func results(_ listedRecipes: ListedRecipe...) -> KitchenSearch {
        .results(listedRecipes.map({ KitchenFeaturePresenter.card(for: $0.entry) }))
    }

    /// Builds a kitchen whose repository lists the recipes, then ends.
    @MainActor
    private func kitchen(listing listedRecipes: [ListedRecipe]) async -> ListedKitchen {
        let recipeRepository = RecipeRepositorySpy()
        let handler = KitchenFeatureHandlerStub()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            recipeRepository: recipeRepository
        )

        recipeRepository.send(listedRecipes)
        recipeRepository.finish()
        await presenter.stackDidAppear()

        return ListedKitchen(
            viewModel: viewModel,
            presenter: presenter,
            recipeRepository: recipeRepository,
            handler: handler
        )
    }

    @MainActor
    @Test("nothing is searched for until text is typed")
    func noSearchAtFirst() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        #expect(kitchen.viewModel.searchText.isEmpty)
        #expect(kitchen.viewModel.search == .idle)
    }

    @MainActor
    @Test("the recipes matching the text reach the view model, from every folder")
    func resultsReachTheViewModel() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons")

        #expect(kitchen.viewModel.searchText == "lardons")
        #expect(kitchen.viewModel.search == results(bourguignon, quiche))
        #expect(bourguignon.entry.folderPath == ["French", "Classic"])
    }

    @MainActor
    @Test("a search matching nothing holds no results, and clearing the text ends the search")
    func noResultsThenCleared() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("mussels")

        #expect(kitchen.viewModel.search == .results([]))

        kitchen.presenter.didChangeSearchText("  ")

        #expect(kitchen.viewModel.search == .idle)
    }

    @MainActor
    @Test("searching reads no recipe")
    func searchingReadsNoRecipe() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        for text in ["l", "la", "lardons", "red wine", "quiche", "mussels", ""] {
            kitchen.presenter.didChangeSearchText(text)
        }

        #expect(kitchen.recipeRepository.readCount == 0)
    }

    @MainActor
    @Test("a listing arriving while searching changes the results")
    func listingChangesTheResults() async {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )

        presenter.didChangeSearchText("lardons")
        recipeRepository.send([bourguignon])
        recipeRepository.send([bourguignon, quiche])
        recipeRepository.finish()
        await presenter.stackDidAppear()

        #expect(viewModel.search == results(bourguignon, quiche))
    }

    @MainActor
    @Test("a recipe opened from a result goes back to the results")
    func backToTheResults() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons")
        kitchen.presenter.didPush(.recipe(bourguignon.entry), from: nil)

        #expect(kitchen.viewModel.pushedScreens == [.recipe(bourguignon.entry)])

        kitchen.presenter.didPop(toCount: 0)

        #expect(kitchen.viewModel.pushedScreens.isEmpty)
        #expect(kitchen.viewModel.searchText == "lardons")
        #expect(kitchen.viewModel.search == results(bourguignon, quiche))
    }

    @MainActor
    @Test("a recipe opened from a result is reported for the next cold start over the top list, without the search")
    func resultReportsTheRecipeAlone() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons")
        kitchen.presenter.didPush(.recipe(bourguignon.entry), from: nil)

        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(recipeID: bourguignon.entry.id))
    }
}
