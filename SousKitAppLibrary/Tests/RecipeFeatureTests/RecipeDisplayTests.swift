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
            source: https://example.com/gratin-dauphinois
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
        #expect(metadata.rows.map(\.value) == ["https://example.com/gratin-dauphinois"])
    }

    @Test("a list in a line left over joins onto one line")
    func metadataRowList() {
        let source = """
            ---
            yield: [6 servings, 3.2 kg]
            ---

            Whisk it.
            """

        #expect(RecipeDisplay.metadata(of: recipe(source).metadata).rows.map(\.value) == ["6 servings, 3.2 kg"])
    }

    @Test("allergens read the escapes of an inline list, and a value without brackets is one allergen")
    func allergens() {
        let escaped = """
            ---
            allergens: [gluten\\, dairy, eggs\\\\]
            ---
            """
        let plain = """
            ---
            allergens: gluten, dairy
            ---
            """

        #expect(RecipeDisplay.metadata(of: recipe(escaped).metadata).allergens == ["gluten, dairy", "eggs\\"])
        #expect(RecipeDisplay.metadata(of: recipe(plain).metadata).allergens == ["gluten, dairy"])
    }

    @Test("a language code reads as a name, and a value that is not one stays as written")
    func languageName() {
        let code = """
            ---
            language: en
            ---
            """
        let plain = """
            ---
            language: french
            ---
            """
        let rows = RecipeDisplay.metadata(of: recipe(code).metadata).rows

        #expect(rows.map(\.key) == ["language"])
        #expect(rows.map(\.value) != ["en"])
        #expect(RecipeDisplay.metadata(of: recipe(plain).metadata).rows.map(\.value) == ["french"])
    }

    @Test("a key written twice keeps the line the facts leave out")
    func repeatedFactKey() {
        let source = """
            ---
            servings: 4
            servings: 6
            ---
            """
        let metadata = RecipeDisplay.metadata(of: recipe(source).metadata)

        #expect(metadata.facts.map(\.value) == ["6"])
        #expect(metadata.rows.map(\.value) == ["4"])
    }

    @Test("a header key reads as a label")
    func metadataRowLabel() {
        #expect(MetadataRow(id: 0, key: "prep-time", value: "30 min").label == "Prep time")
    }

    @Test("a key the screen has a label for is known however the file writes it")
    func knownMetadataKey() {
        #expect(MetadataRow(id: 0, key: "Time Required", value: "1 h").knownKey == .timeRequired)
        #expect(MetadataRow(id: 0, key: "time-required", value: "1 h").knownKey == .timeRequired)
        #expect(MetadataRow(id: 0, key: "make-ahead", value: "best assembled a day ahead").knownKey == nil)
    }

    @Test("staples without an amount are named after the rows, once each")
    func ingredientStaples() {
        let source = """
            Season @{1.2 kg} beef@ with @salt@:staple, @{1/4 tsp} black pepper@:staple, and more @salt@:staple.
            """
        let ingredientList = RecipeDisplay.ingredientList(of: recipe(source))

        #expect(ingredientList.rows.map(\.name) == ["beef", "black pepper"])
        #expect(ingredientList.staples == ["salt"])
    }

    @Test("a staple the list already has a row for is not named after it as well")
    func stapleWithARowOfItsOwn() {
        let source = """
            Season @{1.2 kg} beef@ with @salt@:staple.

            Stir in @{1/4 tsp} salt@:staple.
            """
        let ingredientList = RecipeDisplay.ingredientList(of: recipe(source))

        #expect(ingredientList.rows.map(\.name) == ["beef", "salt"])
        #expect(ingredientList.staples.isEmpty)
    }

    @Test("staples are listed as rows when nothing else is")
    func ingredientStaplesOnly() {
        let ingredientList = RecipeDisplay.ingredientList(of: recipe("Season with @salt@:staple."))

        #expect(ingredientList.rows.map(\.name) == ["salt"])
        #expect(ingredientList.staples.isEmpty)
    }

    @Test("an ingredient annotated twice is one row, with its amounts summed")
    func ingredientAmounts() {
        let source = """
            Soften @{4 cloves} garlic@ in a #stockpot#.

            Pound @{3 cloves} garlic@ in a #mortar#.
            """
        let ingredientList = RecipeDisplay.ingredientList(of: recipe(source))

        #expect(ingredientList.rows.map(\.name) == ["garlic"])
        #expect(ingredientList.rows.map(\.amount) == ["7 cloves"])
    }

    @Test("a staple and a piece of cookware are named once however the file writes them")
    func namesThatDifferInWriting() {
        let source = """
            Season @{1.2 kg} beef@ with @Salt@:staple in a #Frying pan#.

            Stir in more @salt@:staple and return it to the #frying pan#.
            """
        let parsed = recipe(source)

        #expect(RecipeDisplay.ingredientList(of: parsed).staples == ["Salt"])
        #expect(RecipeDisplay.cookwareNames(of: parsed) == ["Frying pan"])
    }

    @Test("cookware reached for twice is named once")
    func cookwareNames() {
        let source = """
            Melt it in a #frying pan# and stir with a #slotted spoon#.

            Return it to the #frying pan#.
            """

        #expect(RecipeDisplay.cookwareNames(of: recipe(source)) == ["frying pan", "slotted spoon"])
    }
}
