@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe search index")
struct RecipeSearchIndexTests {
    private let parser = SousParser()

    /// A recipe found by its path, with the header `header` already read and the given ingredient names.
    private func listedRecipe(
        _ path: String,
        header: String,
        ingredientNames: [String] = []
    ) -> ListedRecipe {
        let components = path.split(separator: "/").map(String.init)

        return ListedRecipe(
            entry: RecipeEntry(
                id: path,
                name: components.last ?? path,
                availability: .downloaded,
                summary: RecipeSummary(recipe: parser.parseRecipe(header).value, parser: parser),
                folderPath: Array(components.dropLast())
            ),
            ingredientNames: ingredientNames
        )
    }

    private var crepes: ListedRecipe {
        listedRecipe(
            "Baking/crepes",
            header: "---\ntitle: Crêpes\ntags: [dessert, classic, french]\n---",
            ingredientNames: ["flour", "eggs", "milk", "melted butter", "salt"]
        )
    }

    private var bourguignon: ListedRecipe {
        listedRecipe(
            "French/Classic/boeuf-bourguignon",
            header: "---\ntitle: Boeuf Bourguignon\ntags: [dinner, classic, french]\n---",
            ingredientNames: ["beef", "lardons", "red wine", "button mushrooms"]
        )
    }

    private var quiche: ListedRecipe {
        listedRecipe(
            "quiche-lorraine",
            header: "---\ntitle: Quiche Lorraine\ntags: [lunch, classic, french]\n---",
            ingredientNames: ["flour", "lardons", "cream", "nutmeg", "gruyere"]
        )
    }

    private var gratin: ListedRecipe {
        listedRecipe(
            "French/Comfort food/gratin-dauphinois",
            header: "---\ntitle: Gratin Dauphinois\ntags: [comfort food, french, make-ahead]\n---",
            ingredientNames: ["potatoes", "milk", "cream", "nutmeg"]
        )
    }

    /// The paths of the recipes a search for `text` finds among `listedRecipes`, in the order shown.
    @MainActor
    private func results(for text: String, in listedRecipes: [ListedRecipe]) -> [String] {
        let index = RecipeSearchIndex()
        index.update(listedRecipes)

        return index.results(matching: RecipeSearchTerms.words(of: text)).map(\.id)
    }

    @MainActor
    @Test("a title is found ignoring accents and case", arguments: ["crepes", "CREPES", "Crêpes", "crêpes"])
    func titleIgnoresAccentsAndCase(text: String) {
        #expect(results(for: text, in: [crepes, bourguignon]) == ["Baking/crepes"])
    }

    @MainActor
    @Test("a search finds a recipe in any folder, however deep")
    func everyFolder() {
        #expect(results(for: "bourguignon", in: [crepes, bourguignon]) == ["French/Classic/boeuf-bourguignon"])
    }

    @MainActor
    @Test("a word searched for finds the words it begins, not those it sits inside")
    func wordPrefixes() {
        #expect(results(for: "bourg", in: [crepes, bourguignon]) == ["French/Classic/boeuf-bourguignon"])
        #expect(results(for: "guignon", in: [crepes, bourguignon]).isEmpty)
    }

    @MainActor
    @Test("a tag is found, each of its words on its own")
    func tags() {
        #expect(results(for: "dessert", in: [crepes, bourguignon]) == ["Baking/crepes"])
        #expect(results(for: "food", in: [crepes, gratin]) == ["French/Comfort food/gratin-dauphinois"])
        #expect(results(for: "make-ahead", in: [crepes, gratin]) == ["French/Comfort food/gratin-dauphinois"])
    }

    @MainActor
    @Test("an ingredient's name is found, each of its words on its own")
    func ingredients() {
        #expect(results(for: "nutmeg", in: [crepes, quiche, gratin]) == [
            "French/Comfort food/gratin-dauphinois",
            "quiche-lorraine"
        ])
        #expect(results(for: "mushrooms", in: [crepes, bourguignon]) == ["French/Classic/boeuf-bourguignon"])
    }

    @MainActor
    @Test("several words find only the recipes matching every one of them, anywhere")
    func everyWordMatches() {
        #expect(results(for: "classic lardons", in: [crepes, bourguignon, gratin]) == [
            "French/Classic/boeuf-bourguignon"
        ])
        #expect(results(for: "crepes lardons", in: [crepes, bourguignon]).isEmpty)
    }

    @MainActor
    @Test("a search matching nothing finds no recipe")
    func noMatch() {
        #expect(results(for: "mussels", in: [crepes, bourguignon, quiche, gratin]).isEmpty)
    }

    @Test("text with no letter or digit holds no word to search for", arguments: ["", "   ", "-", " , "])
    func blankText(text: String) {
        #expect(RecipeSearchTerms.words(of: text).isEmpty)
    }

    @MainActor
    @Test("no word searched for matches no recipe")
    func noWords() {
        #expect(results(for: "", in: [crepes, bourguignon]).isEmpty)
    }

    @MainActor
    @Test("a recipe with no summary read is found by its name alone")
    func unreadRecipe() {
        let unread = ListedRecipe(entry: RecipeEntry(id: "crepes", name: "crepes", availability: .notDownloaded))

        #expect(results(for: "crep", in: [unread]) == ["crepes"])
    }

    @MainActor
    @Test("recipes found by title come first, then by tag, then by ingredient, each by title")
    func order() {
        let madeleines = listedRecipe(
            "Baking/madeleines",
            header: "---\ntitle: Madeleines\ntags: [baking, classic, french]\n---",
            ingredientNames: ["melted butter", "flour", "caster sugar"]
        )
        let brioche = listedRecipe(
            "brioche",
            header: "---\ntitle: Brioche\ntags: [baking, classic, french]\n---",
            ingredientNames: ["flour", "yeast", "butter"]
        )
        let butterBrioche = listedRecipe(
            "Baking/brioche",
            header: "---\ntitle: Butter Brioche\n---",
            ingredientNames: ["flour", "yeast"]
        )

        #expect(results(for: "b", in: [madeleines, crepes, brioche, butterBrioche, bourguignon]) == [
            "French/Classic/boeuf-bourguignon",
            "brioche",
            "Baking/brioche",
            "Baking/madeleines",
            "Baking/crepes"
        ])
    }

    @MainActor
    @Test("a search below a folder finds only the recipes in it and the folders below it")
    func belowAFolder() {
        let index = RecipeSearchIndex()
        index.update([crepes, bourguignon, quiche, gratin])

        let found = index.results(matching: ["nutmeg"], below: ["French"]).map(\.id)

        #expect(found == ["French/Comfort food/gratin-dauphinois"])
        #expect(index.results(matching: ["classic"], below: ["French", "Classic"]).map(\.id) == [
            "French/Classic/boeuf-bourguignon"
        ])
    }

    @MainActor
    @Test("recipes sharing a title are ordered by where they sit")
    func sameTitle() {
        let top = listedRecipe("quiche-lorraine", header: "---\ntitle: Quiche Lorraine\n---")
        let nested = listedRecipe("French/Classic/quiche-lorraine", header: "---\ntitle: Quiche Lorraine\n---")

        #expect(results(for: "quiche", in: [top, nested]) == ["French/Classic/quiche-lorraine", "quiche-lorraine"])
    }
}
