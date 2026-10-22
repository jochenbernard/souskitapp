@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory reader")
final class RecipeDirectoryReaderTests {
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let directory: TemporaryDirectory
    private let fileStatuses = FileStatusStub()

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDirectoryReaderTests")
    }

    private func readRecipeFiles() throws -> [RecipeFile] {
        let reader = RecipeDirectoryReader(recipeDirectory: directory.recipeDirectory, fileStatus: fileStatuses.status)
        return try reader.readRecipeFiles()
    }

    private func readRecipeEntries() throws -> [RecipeEntry] {
        try readRecipeFiles().map({ $0.recipeEntry(summary: nil) })
    }

    private func readNames() throws -> [String] {
        try readRecipeEntries().map(\.name)
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

        #expect(try readRecipeEntries().map(\.availability) == [.downloaded])
    }

    @Test("an iCloud placeholder is listed under the recipe's name")
    func placeholder() throws {
        try directory.writeFile(named: ".Crepes.sous.icloud")

        let recipeEntries = try readRecipeEntries()

        #expect(recipeEntries.map(\.name) == ["Crepes"])
        #expect(recipeEntries.map(\.fileName) == ["Crepes.sous"])
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
        try directory.writeFile(named: "crepes.sous")
        try directory.setModificationDate(date, ofFileNamed: "crepes.sous")

        #expect(try readRecipeFiles().map(\.modificationDate) == [date])
    }

    @Test("a placeholder is listed with the date iCloud promises for the recipe, not with its own")
    func placeholderModificationDate() throws {
        try directory.writeFile(named: ".Crepes.sous.icloud")
        fileStatuses.set(.notDownloaded(modifiedAt: date), forFileNamed: "Crepes.sous")

        #expect(try readRecipeFiles().map(\.modificationDate) == [date])
    }

    @Test("a file whose newer version waits in iCloud is listed as outdated and on its way, at its date")
    func outdatedFile() throws {
        try directory.writeFile(named: "crepes.sous")
        fileStatuses.set(.outdated(modifiedAt: date), forFileNamed: "crepes.sous")

        let recipeFiles = try readRecipeFiles()

        #expect(recipeFiles.map(\.isOutdated) == [true])
        #expect(recipeFiles.map(\.availability) == [.downloading])
        #expect(recipeFiles.map(\.modificationDate) == [date])
    }

    @Test("a file on disk is not outdated")
    func currentFile() throws {
        try directory.writeFile(named: "crepes.sous")

        #expect(try readRecipeFiles().map(\.isOutdated) == [false])
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
