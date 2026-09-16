@testable import RecipeFeature
import SousKit
import Testing

@Suite("Recipe display")
struct RecipeDisplayTests {
    private let parser = SousParser()

    private func recipe(_ source: String) -> Recipe {
        parser.parseRecipe(source).value
    }

    @Test("the header sorts into facts, tags, allergens, and the lines left over, without the title")
    func metadata() {
        let source = """
            ---
            title: Boeuf Bourguignon
            cook-time: 3 h
            servings: 6
            tags: [dinner, french]
            allergens: [gluten, dairy]
            source: https://example.com
            prep-time: 30 min
            ---

            Braise it.
            """
        let metadata = RecipeDisplay.metadata(of: recipe(source).metadata)

        #expect(metadata.facts.map(\.kind) == [.servings, .prepTime, .cookTime])
        #expect(metadata.facts.map(\.value) == ["6", "30 min", "3 h"])
        #expect(metadata.tags == ["dinner", "french"])
        #expect(metadata.allergens == ["gluten", "dairy"])
        #expect(metadata.rows.map(\.key) == ["source"])
        #expect(metadata.rows.map(\.value) == ["https://example.com"])
    }

    @Test("a list in a line left over joins onto one line")
    func metadataRowList() {
        let source = """
            ---
            yield: [12 crepes, 1 l batter]
            ---

            Whisk it.
            """

        #expect(RecipeDisplay.metadata(of: recipe(source).metadata).rows.map(\.value) == ["12 crepes, 1 l batter"])
    }

    @Test("allergens read the escapes of an inline list, and a value without brackets is one allergen")
    func allergens() {
        let escaped = """
            ---
            allergens: [nuts\\, tree, dairy\\\\]
            ---
            """
        let plain = """
            ---
            allergens: gluten, dairy
            ---
            """

        #expect(RecipeDisplay.metadata(of: recipe(escaped).metadata).allergens == ["nuts, tree", "dairy\\"])
        #expect(RecipeDisplay.metadata(of: recipe(plain).metadata).allergens == ["gluten, dairy"])
    }

    @Test("a header key reads as a label")
    func metadataRowLabel() {
        #expect(MetadataRow(id: 0, key: "prep-time", value: "30 min").label == "Prep time")
    }

    @Test("staples without an amount are named after the rows, once each")
    func ingredientStaples() {
        let source = """
            Season @{1.2 kg} beef@ with @salt@:staple, @{1/2 tsp} pepper@:staple, and more @salt@:staple.
            """
        let ingredientList = RecipeDisplay.ingredientList(of: recipe(source))

        #expect(ingredientList.rows.map(\.name) == ["beef", "pepper"])
        #expect(ingredientList.staples == ["salt"])
    }

    @Test("staples are listed as rows when nothing else is")
    func ingredientStaplesOnly() {
        let ingredientList = RecipeDisplay.ingredientList(of: recipe("Season with @salt@:staple."))

        #expect(ingredientList.rows.map(\.name) == ["salt"])
        #expect(ingredientList.staples.isEmpty)
    }

    @Test("cookware reached for twice is named once")
    func cookwareNames() {
        let source = """
            Melt it in a #pan# and stir with a #spoon#.

            Return it to the #pan#.
            """

        #expect(RecipeDisplay.cookwareNames(of: recipe(source)) == ["pan", "spoon"])
    }
}
