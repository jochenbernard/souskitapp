@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory reader")
final class RecipeDirectoryReaderTests {
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDirectoryReaderTests")
    }

    private func readListing() throws -> RecipeDirectoryListing {
        try RecipeDirectoryReader(recipeDirectory: directory.recipeDirectory).readListing()
    }

    private func readRecipeFiles() throws -> [RecipeFile] {
        try readListing().recipeFiles
    }

    private func readRecipeEntries() throws -> [RecipeEntry] {
        try readRecipeFiles().map({ $0.recipeEntry(summary: nil) })
    }

    private func readNames() throws -> [String] {
        try readRecipeEntries().map(\.name)
    }

    private func readPaths() throws -> [String] {
        try readRecipeFiles().map(\.path)
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

    @Test("the recipes in the directories inside are listed by where they sit, at any depth")
    func nestedRecipes() throws {
        try directory.makeDirectory(named: "Baking")
        try directory.makeDirectory(named: "French/Comfort food")
        try directory.writeFile(named: "Baking/madeleines.sous")
        try directory.writeFile(named: "French/Comfort food/gratin-dauphinois.sous")
        try directory.writeFile(named: "crepes.sous")

        #expect(
            try readPaths() == ["Baking/madeleines.sous", "crepes.sous", "French/Comfort food/gratin-dauphinois.sous"]
        )
        #expect(try readRecipeEntries().map(\.folderPath) == [["Baking"], [], ["French", "Comfort food"]])
    }

    @Test("files sharing a name in different directories are listed apart")
    func sameFileNameInTwoDirectories() throws {
        try directory.makeDirectory(named: "Sauce")
        try directory.writeFile(named: "vinaigrette.sous")
        try directory.writeFile(named: "Sauce/vinaigrette.sous")

        #expect(try readPaths() == ["Sauce/vinaigrette.sous", "vinaigrette.sous"])
    }

    @Test("every directory read is listed, the top as an empty path, those holding no recipe included")
    func directoryPaths() throws {
        try directory.makeDirectory(named: "French/Classic")
        try directory.makeDirectory(named: "images")
        try directory.writeFile(named: "images/gratin-dauphinois.jpg")

        #expect(try readListing().directoryPaths == ["", "French", "French/Classic", "images"])
        #expect(try readPaths().isEmpty)
    }

    @Test("a hidden file is left out")
    func hiddenFile() throws {
        try directory.writeFile(named: ".crepes.sous")

        #expect(try readNames().isEmpty)
    }

    @Test("a hidden directory and everything in it are left out")
    func hiddenDirectory() throws {
        try directory.makeDirectory(named: ".archive/Baking")
        try directory.writeFile(named: ".archive/vinaigrette.sous")
        try directory.writeFile(named: ".archive/Baking/brioche.sous")
        try directory.writeFile(named: ".archive/.Crepes.sous.icloud")

        #expect(try readPaths().isEmpty)
        #expect(try readListing().directoryPaths == [""])
    }

    @Test("a package and everything in it are left out")
    func package() throws {
        try directory.makeDirectory(named: "Notes.rtfd")
        try directory.writeFile(named: "Notes.rtfd/crepes.sous")

        #expect(try readPaths().isEmpty)
        #expect(try readListing().directoryPaths == [""])
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

        #expect(try readRecipeEntries().map(\.availability) == [.downloaded])
    }

    @Test("an iCloud placeholder is listed under the recipe's name")
    func placeholder() throws {
        try directory.writeFile(named: ".Crepes.sous.icloud")

        let recipeEntries = try readRecipeEntries()

        #expect(recipeEntries.map(\.name) == ["Crepes"])
        #expect(recipeEntries.map(\.path) == ["Crepes.sous"])
        #expect(recipeEntries.map(\.availability) == [.notDownloaded])
    }

    @Test("an iCloud placeholder in a directory inside is listed where its recipe sits")
    func nestedPlaceholder() throws {
        try directory.makeDirectory(named: "Baking/Classic")
        try directory.writeFile(named: "Baking/Classic/.brioche.sous.icloud")

        let recipeEntries = try readRecipeEntries()

        #expect(recipeEntries.map(\.path) == ["Baking/Classic/brioche.sous"])
        #expect(recipeEntries.map(\.folderPath) == [["Baking", "Classic"]])
        #expect(recipeEntries.map(\.availability) == [.notDownloaded])
    }

    @Test("a placeholder beside the file it stands in for is listed once")
    func placeholderBesideItsFile() throws {
        try directory.writeFile(named: "Crepes.sous")
        try directory.writeFile(named: ".Crepes.sous.icloud")

        let recipeEntries = try readRecipeEntries()

        #expect(recipeEntries.map(\.name) == ["Crepes"])
        #expect(recipeEntries.map(\.availability) == [.downloaded])
    }

    @Test("a file on disk is listed with the date its contents last changed")
    func modificationDate() throws {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        try directory.writeFile(named: "crepes.sous")
        try directory.setModificationDate(date, ofFileNamed: "crepes.sous")

        #expect(try readRecipeFiles().map(\.modificationDate) == [date])
    }

    @Test("a placeholder is listed without its own date, which is not the recipe's")
    func placeholderModificationDate() throws {
        try directory.writeFile(named: ".Crepes.sous.icloud")

        #expect(try readRecipeFiles().map(\.modificationDate) == [nil])
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
            try readRecipeEntries()
        }
    }
}
