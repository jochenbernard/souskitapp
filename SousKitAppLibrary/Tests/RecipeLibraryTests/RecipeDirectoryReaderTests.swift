import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory reader")
final class RecipeDirectoryReaderTests {
    private let directoryURL: URL

    init() throws {
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(path: "RecipeDirectoryReaderTests.\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        self.directoryURL = url
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func writeFile(named fileName: String) throws {
        try Data().write(to: directoryURL.appending(path: fileName))
    }

    private func makeDirectory(named name: String) throws {
        try FileManager.default.createDirectory(
            at: directoryURL.appending(path: name),
            withIntermediateDirectories: true
        )
    }

    private func readRecipeFiles() throws -> [RecipeFile] {
        let reader = RecipeDirectoryReader(recipeDirectory: RecipeDirectory(url: directoryURL))
        return try reader.readRecipeFiles()
    }

    private func readNames() throws -> [String] {
        try readRecipeFiles().map(\.name)
    }

    @Test("an empty directory holds no recipes")
    func emptyDirectory() throws {
        #expect(try readNames().isEmpty)
    }

    @Test("a file that is not a recipe is left out")
    func otherExtensions() throws {
        try writeFile(named: "crepes.sous")
        try writeFile(named: "notes.txt")
        try writeFile(named: "README.md")
        try writeFile(named: "sous")

        #expect(try readNames() == ["Crepes"])
    }

    @Test("an extension in capitals is a recipe")
    func capitalizedExtension() throws {
        try writeFile(named: "MADELEINES.SOUS")

        #expect(try readNames() == ["MADELEINES"])
    }

    @Test("a directory named like a recipe is left out")
    func directoryNamedLikeARecipe() throws {
        try makeDirectory(named: "Desserts.sous")

        #expect(try readNames().isEmpty)
    }

    @Test("what a directory inside holds is left out")
    func nestedRecipes() throws {
        try makeDirectory(named: "Desserts")
        try Data().write(to: directoryURL.appending(path: "Desserts/madeleines.sous"))
        try writeFile(named: "crepes.sous")

        #expect(try readNames() == ["Crepes"])
    }

    @Test("a hidden file is left out")
    func hiddenFile() throws {
        try writeFile(named: ".crepes.sous")

        #expect(try readNames().isEmpty)
    }

    @Test("recipes are ordered by name")
    func ordering() throws {
        try writeFile(named: "vinaigrette.sous")
        try writeFile(named: "brioche.sous")
        try writeFile(named: "Crepes.sous")

        #expect(try readNames() == ["Brioche", "Crepes", "Vinaigrette"])
    }

    @Test("numbers in names order by value")
    func numericOrdering() throws {
        try writeFile(named: "recipe-10.sous")
        try writeFile(named: "recipe-2.sous")

        #expect(try readNames() == ["Recipe 2", "Recipe 10"])
    }

    @Test("a file on disk is downloaded")
    func downloadedAvailability() throws {
        try writeFile(named: "crepes.sous")

        #expect(try readRecipeFiles().map(\.availability) == [.downloaded])
    }

    @Test("an iCloud placeholder is listed under the recipe's name")
    func placeholder() throws {
        try writeFile(named: ".Crepes.sous.icloud")

        let recipeFiles = try readRecipeFiles()

        #expect(recipeFiles.map(\.name) == ["Crepes"])
        #expect(recipeFiles.map(\.fileName) == ["Crepes.sous"])
        #expect(recipeFiles.map(\.availability) == [.notDownloaded])
    }

    @Test("a placeholder beside the file it stands in for is listed once")
    func placeholderBesideItsFile() throws {
        try writeFile(named: "Crepes.sous")
        try writeFile(named: ".Crepes.sous.icloud")

        let recipeFiles = try readRecipeFiles()

        #expect(recipeFiles.map(\.name) == ["Crepes"])
        #expect(recipeFiles.map(\.availability) == [.downloaded])
    }

    @Test("a placeholder for something that is not a recipe is left out")
    func placeholderForOtherFile() throws {
        try writeFile(named: ".notes.txt.icloud")

        #expect(try readNames().isEmpty)
    }

    @Test("reading a directory that is gone throws")
    func missingDirectory() throws {
        try FileManager.default.removeItem(at: directoryURL)

        #expect(throws: (any Error).self) {
            try readRecipeFiles()
        }
    }
}
