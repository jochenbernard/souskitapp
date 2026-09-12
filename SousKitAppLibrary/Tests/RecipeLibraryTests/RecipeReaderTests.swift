import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe reader")
final class RecipeReaderTests {
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeReaderTests")
    }

    private func readRecipe(of recipeFile: RecipeFile) throws -> Recipe {
        let reader = RecipeReader(recipeDirectory: directory.recipeDirectory)
        return try reader.readRecipe(of: recipeFile).value
    }

    private func crepes() throws -> RecipeFile {
        try directory.writeFile(
            named: "crepes.sous",
            """
            ---
            title: Crepes
            servings: 4
            tags: [dessert, french]
            ---

            Whisk @{200 g} flour@ into a batter with @{4} eggs@ in a #bowl#, then rest it ~1 h~.

            Wipe a #crepe pan# with @{10 g} butter@ and cook each crepe ~1 min~ a side.
            """
        )
    }

    @Test("the header reads back as metadata")
    func metadata() throws {
        let recipe = try readRecipe(of: crepes())

        #expect(recipe.metadata.title == "Crepes")
        #expect(recipe.metadata.servings == 4.0)
        #expect(recipe.metadata.tags == ["dessert", "french"])
    }

    @Test("the ingredients read back in document order, with their amounts")
    func ingredients() throws {
        let recipe = try readRecipe(of: crepes())

        #expect(recipe.ingredients.map(\.name) == ["flour", "eggs", "butter"])
        #expect(recipe.ingredients.compactMap(\.amount).map(\.text) == ["200 g", "4", "10 g"])
    }

    @Test("the cookware reads back in document order")
    func cookware() throws {
        let recipe = try readRecipe(of: crepes())

        #expect(recipe.cookware.map(\.name) == ["bowl", "crepe pan"])
    }

    @Test("a blank line parts one step from the next")
    func steps() throws {
        let recipe = try readRecipe(of: crepes())

        #expect(recipe.steps.count == 2)
        #expect(recipe.timers.map(\.text) == ["1 h", "1 min"])
    }

    @Test("a heading names the group its steps sit in")
    func groups() throws {
        let recipeFile = try directory.writeFile(
            named: "bouillabaisse.sous",
            """
            ---
            title: Bouillabaisse
            ---

            ## Court-Bouillon
            Soften @{2} fennel bulbs@ in a #stockpot#.

            ## Rouille
            Pound @{3 cloves} garlic@ in a #mortar#.
            """
        )

        let recipe = try readRecipe(of: recipeFile)

        #expect(recipe.groups.map(\.name) == ["Court-Bouillon", "Rouille"])
        #expect(recipe.groups.map(\.steps.count) == [1, 1])
    }

    @Test("a file that is not a recipe still parses, holding no steps")
    func notARecipe() throws {
        let recipeFile = try directory.writeFile(named: "empty.sous", "")

        let recipe = try readRecipe(of: recipeFile)

        #expect(recipe.metadata.title == nil)
        #expect(recipe.steps.isEmpty)
    }

    @Test("reading a recipe that is gone throws")
    func missingRecipe() throws {
        let recipeFile = try directory.writeFile(named: "crepes.sous", "Whisk.")
        try FileManager.default.removeItem(at: recipeFile.url)

        #expect(throws: (any Error).self) {
            try readRecipe(of: recipeFile)
        }
    }
}
