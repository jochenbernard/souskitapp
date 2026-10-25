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

    private let croque = ListedRecipe(
        entry: .stubbed(at: "Lunch/French/Classic/croque-monsieur"),
        ingredientNames: ["pain de mie", "ham", "gruyere", "butter"]
    )

    private let gratin = ListedRecipe(
        entry: .stubbed(at: "French/Comfort food/gratin-dauphinois"),
        ingredientNames: ["potatoes", "milk", "cream", "nutmeg"]
    )

    /// A search for the text finding the recipes, in the order given.
    private func search(_ text: String, finding listedRecipes: ListedRecipe...) -> KitchenSearch {
        KitchenSearch(
            text: text,
            isSearching: true,
            results: listedRecipes.map({ KitchenRecipeCard(recipeEntry: $0.entry) })
        )
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

        #expect(kitchen.viewModel.searches.isEmpty)
    }

    @MainActor
    @Test("the recipes matching the text reach the view model, from every folder")
    func resultsReachTheViewModel() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons", in: [])

        #expect(kitchen.viewModel.searches == [[]: search("lardons", finding: bourguignon, quiche)])
    }

    @MainActor
    @Test("a search matching nothing holds no results, and clearing the text ends the search")
    func noResultsThenCleared() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("mussels", in: [])

        #expect(kitchen.viewModel.searches[[]] == search("mussels"))

        kitchen.presenter.didChangeSearchText("  ", in: [])

        #expect(kitchen.viewModel.searches[[]] == KitchenSearch(text: "  ", isSearching: false, results: []))

        kitchen.presenter.didChangeSearchText("", in: [])

        #expect(kitchen.viewModel.searches.isEmpty)
    }

    @MainActor
    @Test("searching reads no recipe")
    func searchingReadsNoRecipe() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        for text in ["l", "la", "lardons", "red wine", "quiche", "mussels", ""] {
            kitchen.presenter.didChangeSearchText(text, in: [])
            kitchen.presenter.didChangeSearchText(text, in: ["French"])
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

        presenter.didChangeSearchText("lardons", in: [])
        recipeRepository.send([bourguignon])
        recipeRepository.send([bourguignon, quiche])
        recipeRepository.finish()
        await presenter.stackDidAppear()

        #expect(viewModel.searches[[]] == search("lardons", finding: bourguignon, quiche))
    }

    @MainActor
    @Test("a recipe opened from a result goes back to the results")
    func backToTheResults() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons", in: [])
        kitchen.presenter.didPush(.recipe(bourguignon.entry), from: nil)

        #expect(kitchen.viewModel.pushedScreens == [.recipe(bourguignon.entry)])

        kitchen.presenter.didPop(toCount: 0)

        #expect(kitchen.viewModel.pushedScreens.isEmpty)
        #expect(kitchen.viewModel.searches[[]] == search("lardons", finding: bourguignon, quiche))
    }

    @MainActor
    @Test("a folder pushed from an active search ends it, text and all, and going back lists the folder again")
    func folderPushEndsTheSearchText() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche, croque, gratin])

        kitchen.presenter.didChangeIsSearchPresented(true, in: [])
        kitchen.presenter.didChangeSearchText("lardons", in: [])
        kitchen.presenter.didChooseFolder(of: bourguignon.entry, from: nil)
        kitchen.presenter.didPop(toCount: 0)

        #expect(kitchen.viewModel.presentedSearchPath == nil)
        #expect(kitchen.viewModel.searches.isEmpty)

        kitchen.presenter.didPush(.folder(["French"]), from: nil)
        kitchen.presenter.didChangeIsSearchPresented(true, in: ["French"])
        kitchen.presenter.didChangeSearchText("cream", in: ["French"])
        kitchen.presenter.didChooseSearch(inFolderAt: ["French", "Comfort food"], from: .folder(["French"]))
        kitchen.presenter.didPop(toCount: 1)

        #expect(kitchen.viewModel.presentedSearchPath == nil)
        #expect(kitchen.viewModel.searches.isEmpty)
    }

    @MainActor
    @Test("a recipe opened from a result is reported for the next cold start over the top list, without the search")
    func resultReportsTheRecipeAlone() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche])

        kitchen.presenter.didChangeSearchText("lardons", in: [])
        kitchen.presenter.didPush(.recipe(bourguignon.entry), from: nil)

        #expect(kitchen.handler.restoration == KitchenFeatureRestoration(recipeID: bourguignon.entry.id))
    }

    @MainActor
    @Test("a folder's search finds only the recipes in it and the folders below it")
    func folderSearch() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche, croque, gratin])

        kitchen.presenter.didPush(.folder(["French"]), from: nil)
        kitchen.presenter.didChangeSearchText("cream", in: ["French"])

        #expect(kitchen.viewModel.searches[["French"]] == search("cream", finding: gratin))
        #expect(kitchen.viewModel.searches[[]] == nil)

        kitchen.presenter.didPush(.folder(["Lunch"]), from: nil)
        kitchen.presenter.didPush(.folder(["Lunch", "French"]), from: .folder(["Lunch"]))
        kitchen.presenter.didChangeSearchText("classic", in: ["Lunch", "French"])

        #expect(kitchen.viewModel.searches[["Lunch", "French"]]?.results.isEmpty == true)

        kitchen.presenter.didChangeSearchText("gruyere", in: ["Lunch", "French"])

        #expect(kitchen.viewModel.searches[["Lunch", "French"]] == search("gruyere", finding: croque))
    }

    @MainActor
    @Test("a recipe opened from a folder's results goes back to them, and is reported under that folder")
    func backToTheFolderResults() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche, croque, gratin])

        kitchen.presenter.didPush(.folder(["French"]), from: nil)
        kitchen.presenter.didChangeSearchText("lardons", in: ["French"])
        kitchen.presenter.didPush(.recipe(bourguignon.entry), from: .folder(["French"]))

        #expect(
            kitchen.handler.restoration
                == KitchenFeatureRestoration(folderPath: ["French"], recipeID: bourguignon.entry.id)
        )

        kitchen.presenter.didPop(toCount: 1)

        #expect(kitchen.viewModel.searches[["French"]] == search("lardons", finding: bourguignon))
    }

    @MainActor
    @Test("a folder popped forgets its search, and the top keeps its own")
    func poppedFolderForgetsItsSearch() async {
        let kitchen = await kitchen(listing: [bourguignon, quiche, croque, gratin])

        kitchen.presenter.didChangeSearchText("lardons", in: [])
        kitchen.presenter.didPush(.folder(["French"]), from: nil)
        kitchen.presenter.didChangeSearchText("nutmeg", in: ["French"])
        kitchen.presenter.didPop(toCount: 0)

        #expect(Array(kitchen.viewModel.searches.keys) == [[]])
    }
}
