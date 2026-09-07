import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe text reader")
final class RecipeTextReaderTests {
    private let directoryURL: URL

    init() throws {
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(path: "RecipeTextReaderTests.\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        self.directoryURL = url
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func writeFile(named fileName: String, _ text: String) throws -> RecipeFile {
        let url = directoryURL.appending(path: fileName)
        try Data(text.utf8).write(to: url)

        return RecipeFile(url: url, availability: .downloaded)
    }

    private func readText(of recipeFile: RecipeFile) throws -> String {
        let reader = RecipeTextReader(recipeDirectory: RecipeDirectory(url: directoryURL))
        return try reader.readText(of: recipeFile)
    }

    @Test("a recipe reads back as it was written")
    func roundTrip() throws {
        let text = """
            ---
            title: Crepes
            servings: 4
            ---

            Whisk @{200 g} flour@ into a batter with @{4} eggs@.
            """
        let recipeFile = try writeFile(named: "crepes.sous", text)

        #expect(try readText(of: recipeFile) == text)
    }

    @Test("the markers are left as written")
    func unparsed() throws {
        let recipeFile = try writeFile(named: "vinaigrette.sous", "Whisk ~1 min~ in a #bowl#.")

        #expect(try readText(of: recipeFile) == "Whisk ~1 min~ in a #bowl#.")
    }

    @Test("text beyond ASCII reads back unchanged")
    func nonASCII() throws {
        let text = "Cr\u{EA}pes with cr\u{E8}me fra\u{EE}che, 180\u{B0}C"
        let recipeFile = try writeFile(named: "crepes.sous", text)

        #expect(try readText(of: recipeFile) == text)
    }

    @Test("an empty recipe reads back as no text")
    func emptyRecipe() throws {
        let recipeFile = try writeFile(named: "empty.sous", "")

        #expect(try readText(of: recipeFile).isEmpty)
    }

    @Test("reading a recipe that is gone throws")
    func missingRecipe() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        try FileManager.default.removeItem(at: recipeFile.url)

        #expect(throws: (any Error).self) {
            try readText(of: recipeFile)
        }
    }

    @Test("a recipe that is not valid UTF-8 throws")
    func undecodableRecipe() throws {
        let url = directoryURL.appending(path: "broken.sous")
        try Data([0xFF, 0xFE, 0xFD]).write(to: url)

        #expect(throws: (any Error).self) {
            try readText(of: RecipeFile(url: url, availability: .downloaded))
        }
    }
}
