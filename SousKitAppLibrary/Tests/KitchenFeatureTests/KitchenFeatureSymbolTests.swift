@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@MainActor
@Suite("Kitchen feature symbols", .timeLimit(.minutes(1)))
struct KitchenFeatureSymbolTests {
    private let parser = SousParser()
    private let recipeRepository = RecipeRepositorySpy()
    private let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")

    /// `Baking/crepes.sous`, read, with `symbol` picked for it, or none.
    private func crepes(picking symbol: String? = nil) throws -> ListedRecipe {
        let recipe = parser.parseRecipe("---\ntitle: Crepes\n---\nWhisk @{200 g} flour@.").value
        let symbolPick = try symbol.map { symbol in
            RecipeSymbolPick(
                symbol: symbol,
                input: try #require(RecipeSymbolInput(listedRecipe: try crepes())),
                promptVersion: 1
            )
        }

        return ListedRecipe(
            entry: RecipeEntry(
                id: "Baking/crepes.sous",
                name: "crepes",
                availability: .downloaded,
                summary: RecipeSummary(
                    metadata: recipe.metadata,
                    parser: parser,
                    symbolPick: symbolPick
                ),
                folderPath: ["Baking"]
            ),
            ingredientNames: recipe.foodIngredientNames
        )
    }

    /// The symbols shown for the recipe on its folder's screen, in its folder's stack and in the top search's results.
    private var shownSymbols: [String] {
        guard case .recipes(let folder) = viewModel.recipeList else {
            return []
        }

        return [
            folder.folder(at: ["Baking"])?.cards.first?.placeholderSymbol,
            folder.folders.first?.stackedCards.first?.placeholderSymbol,
            viewModel.searches[[]]?.results.first?.placeholderSymbol
        ]
        .compactMap(\.self)
    }

    /// Waits until the recipe is shown in all three places with `symbol`, or the suite's time limit ends the test.
    private func waitForSymbols(_ symbol: String) async throws {
        while shownSymbols != [symbol, symbol, symbol] {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("a recipe shows the default symbol until one is picked, and the picked one once it lands, wherever it shows")
    func pickedSymbol() async throws {
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )
        let task = Task {
            await presenter.stackDidAppear()
        }
        defer {
            task.cancel()
        }

        recipeRepository.send([try crepes()])

        while shownSymbols.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        presenter.didChangeSearchText("crepes", in: [])

        #expect(shownSymbols == ["fork.knife", "fork.knife", "fork.knife"])

        recipeRepository.send([try crepes(picking: "birthday.cake")])

        try await waitForSymbols("birthday.cake")
    }
}
