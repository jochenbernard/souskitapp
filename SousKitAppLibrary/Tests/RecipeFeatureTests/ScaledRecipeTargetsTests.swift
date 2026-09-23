@testable import RecipeFeature
import SousKit
import Testing

@Suite("Scaled recipe targets")
struct ScaledRecipeTargetsTests {
    private let parser = SousParser()

    private func scaledRecipe(_ source: String, scale: RecipeScale? = nil) -> ScaledRecipe {
        ScaledRecipe(
            asWritten: parser.parseRecipe(source).value,
            parser: parser,
            scale: scale
        )
    }

    private func amounts(of recipe: Recipe) -> [String?] {
        recipe.ingredients.map(\.amount?.text)
    }

    @Test(
        "a yield SousKit cannot scale toward is not offered",
        arguments: ["[2-3 loaves]", "[a jar]", "[1 l, 2 l]", "[1-2 l, 1 l]", "[0 kg, 1 kg]", "[0.0000001 kg]"]
    )
    func yieldsLeftOut(_ yields: String) {
        let source = """
            ---
            title: Vinaigrette
            yield: \(yields)
            ---

            Whisk @{1 tsp} dijon mustard@.
            """

        #expect(scaledRecipe(source).targets == [.multiplier])
    }

    @Test("a yield of a bare number is one to scale toward")
    func yieldWithoutAUnit() {
        let source = """
            ---
            title: Madeleines
            yield: [12]
            ---

            Whisk @{2} eggs@ into @{100 g} flour@.
            """
        let scale = RecipeScale(target: .yield(unit: ""), value: 24.0)
        let scaled = scaledRecipe(source, scale: scale)

        #expect(scaled.targets == [.yield(unit: ""), .multiplier])
        #expect(scaled.scale == scale)
        #expect(scaled.scaled.metadata.yields.map(\.text) == ["24"])
        #expect(amounts(of: scaled.scaled) == ["4", "200 g"])
    }

    @Test("a whole number of a yield whose unit opens on a fraction is not read as a mixed number")
    func yieldInAUnitOpeningOnAFraction() {
        let source = """
            ---
            title: Vinaigrette
            yield: [1.5 1/2-litre jars]
            ---

            Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
            """
        let scale = RecipeScale(target: .yield(unit: "1/2-litre jars"), value: 3.0)
        let scaled = scaledRecipe(source, scale: scale)

        #expect(scaled.scale == scale)
        #expect(amounts(of: scaled.scaled) == ["2 tsp", "4 tbsp"])
    }

    @Test("a yield in servings is left to the servings the header already declares")
    func yieldInServings() {
        let source = """
            ---
            title: Crepes
            servings: 4
            yield: [4 servings, 12 crepes]
            ---

            Whisk @{4} eggs@.
            """

        #expect(scaledRecipe(source).targets == [.servings, .yield(unit: "crepes"), .multiplier])
    }

    @Test(
        "servings SousKit cannot scale toward are not offered",
        arguments: ["servings: 4-6", "servings: 4\nyield: [8 servings]"]
    )
    func servingsLeftOut(_ header: String) {
        let source = """
            ---
            title: Crepes
            \(header)
            ---

            Whisk @{4} eggs@.
            """
        let scaled = scaledRecipe(source)

        #expect(scaled.targets == [.multiplier])
        #expect(scaled.scale == RecipeScale(target: .multiplier, value: 1.0))
    }

    @Test("a scale on a target the header does not declare falls back to the default")
    func undeclaredTarget() {
        let scale = RecipeScale(target: .yield(unit: "servings"), value: 8.0)
        let source = """
            ---
            title: Crepes
            servings: 4
            yield: [4 servings]
            ---

            Whisk @{4} eggs@.
            """

        #expect(scaledRecipe(source, scale: scale).isDefault)
    }
}
