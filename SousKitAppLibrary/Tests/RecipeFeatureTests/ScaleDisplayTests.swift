@testable import RecipeFeature
import RecipeScaling
import SousKit
import Testing

@Suite("Scale display")
struct ScaleDisplayTests {
    private let parser = SousParser()

    private func scaled(_ source: String, scale: RecipeScale) -> ScaledRecipe {
        ScaledRecipe(
            asWritten: parser.parseRecipe(source).value,
            parser: parser,
            scale: scale
        )
    }

    private let crepes = """
        ---
        title: Crepes
        servings: 4
        ---

        Whisk @{4} eggs@.
        """

    private let vinaigrette = """
        ---
        title: Vinaigrette
        ---

        Whisk @{1 tsp} dijon mustard@.
        """

    @Test("the sheet offers the targets to choose between, and what the others come to")
    func targetsAndWhatFollows() {
        let recipe = scaled(crepes, scale: RecipeScale(target: .servings, value: 8.0))
        let display = ScaleDisplay(recipe: recipe, text: "8")

        #expect(display.target == .servings)
        #expect(display.text == "8")
        #expect(display.targets == [.servings, .multiplier])
        #expect(display.follows == [RecipeScale(target: .multiplier, value: 2.0)])
        #expect(!display.isDefault)
    }

    @Test("a yield reads along with the other targets, and is one to choose")
    func yieldAmongTheTargets() {
        let source = """
            ---
            title: Crepes
            servings: 4
            yield: [12 crepes]
            ---

            Whisk @{4} eggs@.
            """
        let recipe = scaled(source, scale: RecipeScale(target: .servings, value: 8.0))
        let display = ScaleDisplay(recipe: recipe, text: "8")

        #expect(display.targets == [.servings, .yield(unit: "crepes"), .multiplier])
        #expect(
            display.follows == [
                RecipeScale(target: .yield(unit: "crepes"), value: 24.0),
                RecipeScale(target: .multiplier, value: 2.0)
            ]
        )
    }

    @Test("one target is no choice, so the sheet offers none")
    func oneTarget() {
        let recipe = scaled(vinaigrette, scale: RecipeScale(target: .multiplier, value: 2.0))
        let display = ScaleDisplay(recipe: recipe, text: "2")

        #expect(display.target == .multiplier)
        #expect(display.targets.isEmpty)
        #expect(display.follows.isEmpty)
    }
}
