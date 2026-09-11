@testable import RecipeFeature
import SousKit
import Testing

@Suite("Recipe display")
struct RecipeDisplayTests {
    private let parser = SousParser()

    private func recipe(_ source: String) -> Recipe {
        parser.parseRecipe(source).value
    }

    @Test("the title is left out of the header rows, and a list joins onto one line")
    func metadataRows() {
        let source = """
            ---
            title: Crepes
            servings: 4
            tags: [dessert, french]
            ---

            Whisk it.
            """
        let rows = RecipeDisplay.metadataRows(of: recipe(source).metadata)

        #expect(rows.map(\.key) == ["servings", "tags"])
        #expect(rows.map(\.value) == ["4", "dessert, french"])
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
