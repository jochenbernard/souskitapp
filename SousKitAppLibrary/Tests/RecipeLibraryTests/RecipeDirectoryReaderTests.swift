import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory reader")
final class RecipeDirectoryReaderTests {
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDirectoryReaderTests")
    }

    private func readRecipeFiles() throws -> [RecipeFile] {
        let reader = RecipeDirectoryReader(recipeDirectory: directory.recipeDirectory)
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
        try directory.writeFile(named: "crepes.sous")
        try directory.writeFile(named: "notes.txt")
        try directory.writeFile(named: "README.md")
        try directory.writeFile(named: "sous")

        #expect(try readNames() == ["crepes"])
    }

    @Test("an extension in capitals is a recipe")
    func capitalizedExtension() throws {
        try directory.writeFile(named: "MADELEINES.SOUS")

        #expect(try readNames() == ["MADELEINES"])
    }

    @Test("a directory named like a recipe is left out")
    func directoryNamedLikeARecipe() throws {
        try directory.makeDirectory(named: "Desserts.sous")

        #expect(try readNames().isEmpty)
    }

    @Test("what a directory inside holds is left out")
    func nestedRecipes() throws {
        try directory.makeDirectory(named: "Desserts")
        try Data().write(to: directory.url.appending(path: "Desserts/madeleines.sous"))
        try directory.writeFile(named: "crepes.sous")

        #expect(try readNames() == ["crepes"])
    }

    @Test("a hidden file is left out")
    func hiddenFile() throws {
        try directory.writeFile(named: ".crepes.sous")

        #expect(try readNames().isEmpty)
    }

    @Test("recipes are ordered by name")
    func ordering() throws {
        try directory.writeFile(named: "vinaigrette.sous")
        try directory.writeFile(named: "brioche.sous")
        try directory.writeFile(named: "Crepes.sous")

        #expect(try readNames() == ["brioche", "Crepes", "vinaigrette"])
    }

    @Test("numbers in names order by value")
    func numericOrdering() throws {
        try directory.writeFile(named: "recipe-10.sous")
        try directory.writeFile(named: "recipe-2.sous")

        #expect(try readNames() == ["recipe 2", "recipe 10"])
    }

    @Test("a file on disk is downloaded")
    func downloadedAvailability() throws {
        try directory.writeFile(named: "crepes.sous")

        #expect(try readRecipeFiles().map(\.availability) == [.downloaded])
    }

    @Test("an iCloud placeholder is listed under the recipe's name")
    func placeholder() throws {
        try directory.writeFile(named: ".Crepes.sous.icloud")

        let recipeFiles = try readRecipeFiles()

        #expect(recipeFiles.map(\.name) == ["Crepes"])
        #expect(recipeFiles.map(\.fileName) == ["Crepes.sous"])
        #expect(recipeFiles.map(\.availability) == [.notDownloaded])
    }

    @Test("a placeholder beside the file it stands in for is listed once")
    func placeholderBesideItsFile() throws {
        try directory.writeFile(named: "Crepes.sous")
        try directory.writeFile(named: ".Crepes.sous.icloud")

        let recipeFiles = try readRecipeFiles()

        #expect(recipeFiles.map(\.name) == ["Crepes"])
        #expect(recipeFiles.map(\.availability) == [.downloaded])
    }

    @Test("a placeholder for something that is not a recipe is left out")
    func placeholderForOtherFile() throws {
        try directory.writeFile(named: ".notes.txt.icloud")

        #expect(try readNames().isEmpty)
    }

    @Test("reading a directory that is gone throws")
    func missingDirectory() throws {
        try FileManager.default.removeItem(at: directory.url)

        #expect(throws: (any Error).self) {
            try readRecipeFiles()
        }
    }
}
