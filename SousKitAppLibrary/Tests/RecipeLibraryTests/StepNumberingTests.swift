@testable import RecipeLibrary
import SousKit
import Testing

@Suite("Step numbering")
struct StepNumberingTests {
    @Test("step numbers run on across the groups")
    func stepNumbers() {
        let source = """
            ## Court-Bouillon
            Soften it.

            Simmer it.

            ## Rouille
            Pound it.
            """
        let recipe = SousParser().parseRecipe(source).value

        #expect(StepNumbering.firstNumber(ofGroupAt: 0, in: recipe) == 1)
        #expect(StepNumbering.firstNumber(ofGroupAt: 1, in: recipe) == 3)
    }
}
