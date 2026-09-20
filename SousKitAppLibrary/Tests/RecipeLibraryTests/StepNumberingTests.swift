@testable import RecipeLibrary
import SousKit
import Testing

@Suite("Step numbering")
struct StepNumberingTests {
    private let parser = SousParser()

    @Test("step numbers run on across the groups")
    func stepNumbers() {
        let source = """
            ## Court-Bouillon
            Soften it.

            Simmer it.

            ## Rouille
            Pound it.
            """
        let recipe = parser.parseRecipe(source).value

        #expect(StepNumbering.numberedGroups(of: recipe).map(\.firstNumber) == [1, 3])
    }

    @Test("each step carries its number within the recipe")
    func numberedSteps() {
        let source = """
            ## Court-Bouillon
            Soften it.

            Simmer it.

            ## Rouille
            Pound it.
            """
        let recipe = parser.parseRecipe(source).value
        let numbers = StepNumbering.numberedGroups(of: recipe).map({ $0.numberedSteps.map(\.number) })

        #expect(numbers == [[1, 2], [3]])
    }

    @Test("a group with no steps leaves the count where it was")
    func emptyGroupKeepsTheCount() {
        let source = """
            ## Court-Bouillon
            Soften it.

            ## Assemble

            ## Rouille
            Pound it.
            """
        let recipe = parser.parseRecipe(source).value
        let numbered = StepNumbering.numberedGroups(of: recipe)

        #expect(numbered.map(\.id) == Array(recipe.groups.indices))
        #expect(numbered.last?.firstNumber == 2)
    }
}
