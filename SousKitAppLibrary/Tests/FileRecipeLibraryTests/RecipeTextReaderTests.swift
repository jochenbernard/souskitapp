@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe text reader")
final class RecipeTextReaderTests {
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeTextReaderTests")
    }

    private func readText(of recipeEntry: RecipeEntry) async throws -> String {
        let reader = RecipeTextReader(recipeDirectory: directory.recipeDirectory, qualityOfService: .userInitiated)
        return try await reader.read(path: recipeEntry.path, availability: recipeEntry.availability).text
    }

    @Test("a recipe reads back as it was written")
    func roundTrip() async throws {
        let text = """
            ---
            title: Crepes
            servings: 4
            ---

            Whisk @{200 g} flour@ into a batter with @{4} eggs@.
            """
        let recipeEntry = try directory.writeFile(named: "crepes.sous", text)

        #expect(try await readText(of: recipeEntry) == text)
    }

    @Test("the markers are left as written")
    func unparsed() async throws {
        let recipeEntry = try directory.writeFile(named: "crepes.sous", "Whisk ~1 min~ in a #mixing bowl#.")

        #expect(try await readText(of: recipeEntry) == "Whisk ~1 min~ in a #mixing bowl#.")
    }

    @Test("text beyond ASCII reads back unchanged")
    func nonASCII() async throws {
        let text = "Whisk @{\u{0663} g} caster sugar@ with @{\u{FF13}} eggs@."
        let recipeEntry = try directory.writeFile(named: "crepes.sous", text)

        #expect(try await readText(of: recipeEntry) == text)
    }

    @Test("an empty recipe reads back as no text")
    func emptyRecipe() async throws {
        let recipeEntry = try directory.writeFile(named: "empty.sous", "")

        #expect(try await readText(of: recipeEntry).isEmpty)
    }

    @Test("reading a recipe that is gone throws")
    func missingRecipe() async throws {
        let recipeEntry = try directory.writeFile(named: "crepes.sous", "Whisk.")
        try FileManager.default.removeItem(at: directory.url.appending(path: recipeEntry.path))

        await #expect(throws: (any Error).self) {
            try await readText(of: recipeEntry)
        }
    }

    @Test("a recipe that is not valid UTF-8 throws")
    func undecodableRecipe() async throws {
        try Data([0xFF, 0xFE, 0xFD]).write(to: directory.url.appending(path: "broken.sous"))

        await #expect(throws: (any Error).self) {
            try await readText(of: RecipeEntry(path: "broken.sous", availability: .downloaded))
        }
    }
}
