@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("File recipe repository", .timeLimit(.minutes(1)))
final class FileRecipeRepositoryTests: Sendable {
    private let parser = SousParser()

    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "FileRecipeRepositoryTests")
    }

    private func makeRepository() -> FileRecipeRepository {
        FileRecipeRepository(
            parser: parser,
            recipeDirectory: directory.recipeDirectory,
            summaryCacheURL: directory.summaryCacheURL
        )
    }

    private func readRecipe(of recipeEntry: RecipeEntry) async throws -> Recipe {
        try await makeRepository().readRecipe(of: recipeEntry).value
    }

    private func crepes() throws -> RecipeEntry {
        try directory.writeFile(
            named: "crepes.sous",
            """
            ---
            title: Crepes
            servings: 4
            tags: [dessert, classic, french]
            ---

            Whisk @{200 g} flour@ into a batter with @{4} eggs@ in a #mixing bowl#, then rest it ~1 h~.

            Wipe a #crepe pan# with @{10 g} butter@ and cook each crepe ~1 min~ a side.
            """
        )
    }

    @Test("the name is the directory's")
    func name() {
        #expect(makeRepository().name == directory.url.lastPathComponent)
    }

    @Test("the recipes in the directory are listed")
    func listedRecipes() async throws {
        try directory.writeFile(named: "crepes.sous")
        let repository = makeRepository()

        for await result in await repository.listedRecipes() {
            #expect(try result.get().map(\.entry.name) == ["crepes"])
            return
        }

        Issue.record("The stream ended before listing a recipe.")
    }

    @Test("the header reads back as metadata")
    func metadata() async throws {
        let recipe = try await readRecipe(of: crepes())

        #expect(recipe.metadata.title == "Crepes")
        #expect(recipe.metadata.servings == 4.0)
        #expect(recipe.metadata.tags == ["dessert", "classic", "french"])
    }

    @Test("the ingredients read back in document order, with their amounts")
    func ingredients() async throws {
        let recipe = try await readRecipe(of: crepes())

        #expect(recipe.ingredients.map(\.name) == ["flour", "eggs", "butter"])
        #expect(recipe.ingredients.compactMap(\.amount).map(\.text) == ["200 g", "4", "10 g"])
    }

    @Test("the cookware reads back in document order")
    func cookware() async throws {
        let recipe = try await readRecipe(of: crepes())

        #expect(recipe.cookware.map(\.name) == ["mixing bowl", "crepe pan"])
    }

    @Test("a blank line parts one step from the next")
    func steps() async throws {
        let recipe = try await readRecipe(of: crepes())

        #expect(recipe.steps.count == 2)
        #expect(recipe.timers.map(\.text) == ["1 h", "1 min"])
    }

    @Test("a heading names the group its steps sit in")
    func groups() async throws {
        let recipeEntry = try directory.writeFile(
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

        let recipe = try await readRecipe(of: recipeEntry)

        #expect(recipe.groups.map(\.name) == ["Court-Bouillon", "Rouille"])
        #expect(recipe.groups.map(\.steps.count) == [1, 1])
    }

    @Test("a file that is not a recipe still parses, holding no steps")
    func notARecipe() async throws {
        let recipeEntry = try directory.writeFile(named: "empty.sous", "")

        let recipe = try await readRecipe(of: recipeEntry)

        #expect(recipe.metadata.title == nil)
        #expect(recipe.steps.isEmpty)
    }

    @Test("recipes sharing a file name in different directories read as themselves")
    func sameFileNameInTwoDirectories() async throws {
        try directory.makeDirectory(named: "Sauce")
        let top = try directory.writeFile(named: "vinaigrette.sous", "---\ntitle: Vinaigrette\n---")
        let nested = try directory.writeFile(named: "Sauce/vinaigrette.sous", "---\ntitle: Vinaigrette Classic\n---")

        #expect(try await readRecipe(of: top).metadata.title == "Vinaigrette")
        #expect(try await readRecipe(of: nested).metadata.title == "Vinaigrette Classic")
    }

    @Test("reading a recipe that is gone throws")
    func missingRecipe() async throws {
        let recipeEntry = try directory.writeFile(named: "crepes.sous", "Whisk.")
        try FileManager.default.removeItem(at: directory.url.appending(path: recipeEntry.path))

        await #expect(throws: (any Error).self) {
            try await readRecipe(of: recipeEntry)
        }
    }
}
