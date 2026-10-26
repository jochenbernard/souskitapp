@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe document repository", .timeLimit(.minutes(1)))
final class RecipeDocumentRepositoryTests {
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDocumentRepositoryTests")
    }

    @Test("a file reads as its recipe, named after the file and the folder it sits in")
    func fileReadsAsRecipe() async throws {
        try directory.writeFile(
            named: "vinaigrette.sous",
            """
            ---
            title: Vinaigrette
            ---

            Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
            """
        )
        let url = directory.url.appending(path: "vinaigrette.sous")
        let repository = RecipeDocumentRepository(url: url, parser: SousParser())

        let recipe = try await repository.readRecipe(of: repository.entry).value

        #expect(recipe.metadata.title == "Vinaigrette")
        #expect(repository.entry.name == "vinaigrette")
        #expect(repository.entry.folderPath.isEmpty)
        #expect(repository.name == directory.url.lastPathComponent)
    }

    @Test("the file is found by its URL, which no file in a directory is found by")
    func fileFoundByURL() {
        let url = directory.url.appending(path: "vinaigrette.sous")
        let repository = RecipeDocumentRepository(url: url, parser: SousParser())

        #expect(repository.recipeID(forFileAt: url) == repository.entry.id)
        #expect(repository.recipeID(forFileAt: directory.url.appending(path: "crepes.sous")) == nil)
        #expect(repository.entry.id != "vinaigrette.sous")
    }

    @Test("a file that is not text fails to read")
    func unreadableFileFails() async throws {
        let url = directory.url.appending(path: "brioche.sous")
        try Data([0xFF, 0xFE, 0x00, 0xD8, 0x80]).write(to: url)
        let repository = RecipeDocumentRepository(url: url, parser: SousParser())

        await #expect(throws: (any Error).self) {
            try await repository.readRecipe(of: repository.entry)
        }
    }
}
