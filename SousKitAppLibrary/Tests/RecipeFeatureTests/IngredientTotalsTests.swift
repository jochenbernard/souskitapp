@testable import RecipeFeature
import SousKit
import Testing

@Suite("Ingredient totals")
struct IngredientTotalsTests {
    private let parser = SousParser()

    private func ingredientRows(_ source: String) -> [IngredientRow] {
        IngredientTotals.rows(of: parser.parseRecipe(source).value.ingredients)
    }

    @Test("an ingredient annotated twice is one row, with the amounts in one unit summed")
    func sharedUnit() {
        let source = """
            Soften @{4 cloves} garlic@ in a #stockpot#.

            Pound @{3 cloves} garlic@ in a #mortar#.
            """
        let rows = ingredientRows(source)

        #expect(rows.map(\.name) == ["garlic"])
        #expect(rows.map(\.amount) == ["7 cloves"])
    }

    @Test("amounts in units that differ are listed side by side, in the order they are written")
    func separateUnits() {
        let source = """
            Soften them in @{4 tbsp} olive oil@ in a #stockpot#.

            Beat in @{100 ml} olive oil@ drop by drop.
            """

        #expect(ingredientRows(source).map(\.amount) == ["4 tbsp + 100 ml"])
    }

    @Test("a unit written again sums into the amount already listed for it")
    func repeatedUnit() {
        let source = """
            Soften them in @{4 tbsp} olive oil@ in a #stockpot#.

            Beat in @{100 ml} olive oil@ drop by drop, then loosen it with @{2 tbsp} olive oil@.
            """

        #expect(ingredientRows(source).map(\.amount) == ["6 tbsp + 100 ml"])
    }

    @Test("every unit sums on its own, however the recipe interleaves them")
    func interleavedUnits() {
        let source = """
            Fry them in @{2 tbsp} butter@ and @{30 g} butter@.

            Butter the #loaf tin# with @{1 tbsp} butter@ and the #gratin dish# with @{10 g} butter@.
            """

        #expect(ingredientRows(source).map(\.amount) == ["3 tbsp + 40 g"])
    }

    @Test("an amount that stands alone reads as the recipe writes it")
    func singleAmount() {
        #expect(ingredientRows("Pound @{1/2 tsp} salt@ in a #mortar#.").map(\.amount) == ["1/2 tsp"])
    }

    @Test("a sum is written as a number, with fractions and decimals resolved")
    func summedNumbers() {
        let halves = ingredientRows("Mix @{1/2 tsp} salt@ and @{1/2 tsp} salt@.")
        let decimals = ingredientRows("Peel @{0.5 kg} potatoes@ and @{0.25 kg} potatoes@.")

        #expect(halves.map(\.amount) == ["1 tsp"])
        #expect(decimals.map(\.amount) == ["0.75 kg"])
    }

    @Test("amounts without a unit sum too")
    func unitlessAmounts() {
        #expect(ingredientRows("Whisk @{4} eggs@ and fold in @{2} eggs@.").map(\.amount) == ["6"])
    }

    @Test("ranges sum end for end, a single amount counting for both ends")
    func ranges() {
        let source = "Pour in @{1-2 tbsp} olive oil@ and @{1 tbsp} olive oil@."

        #expect(ingredientRows(source).map(\.amount) == ["2-3 tbsp"])
    }

    @Test("an amount with no number to sum stays as written, however often it is repeated")
    func impreciseAmounts() {
        let source = "Add @{a pinch} salt@, @{a pinch} salt@, and @{10 g} salt@."

        #expect(ingredientRows(source).map(\.amount) == ["a pinch + a pinch + 10 g"])
    }

    @Test("an annotation without an amount adds nothing, and a name never annotated with one has none")
    func withoutAmount() {
        let some = ingredientRows("Butter a #loaf tin# with @butter@, then beat in @{250 g} butter@.")
        let none = ingredientRows("Scatter with @parsley@ and serve the rest of the @parsley@ beside it.")

        #expect(some.map(\.amount) == ["250 g"])
        #expect(none.map(\.name) == ["parsley"])
        #expect(none.map(\.amount) == [nil])
    }

    @Test("a name written with other capitals or accents reaches the row already listed for it")
    func namesThatDifferInWriting() {
        let capitals = ingredientRows("Sift @{200 g} Flour@, then fold in @{50 g} flour@.")
        let accents = ingredientRows("Serve with @Cro\u{FB}tons@ and scatter the rest of the @croutons@ over.")

        #expect(capitals.map(\.name) == ["Flour"])
        #expect(capitals.map(\.amount) == ["250 g"])
        #expect(accents.map(\.name) == ["Cro\u{FB}tons"])
    }

    @Test("the rows follow the order the recipe first names each ingredient")
    func rowOrder() {
        let source = "Whisk @{200 g} flour@ with @{4} eggs@, then sift in @{50 g} flour@."
        let rows = ingredientRows(source)

        #expect(rows.map(\.name) == ["flour", "eggs"])
        #expect(rows.map(\.amount) == ["250 g", "4"])
    }
}
