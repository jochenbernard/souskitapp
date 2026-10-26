import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("File recipe repository", .timeLimit(.minutes(1)))
final class FileRecipeRepositoryTests: Sendable {
    private let parser = SousParser()

    let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "FileRecipeRepositoryTests")
    }

    /// A repository over the directory, picking no symbols unless given a picker that can.
    func makeRepository(
        symbolPicker: RecipeSymbolPicker = RecipeSymbolPickerStub(isAvailable: false)
    ) -> FileRecipeRepository {
        FileRecipeRepository(
            parser: parser,
            recipeDirectory: directory.recipeDirectory,
            symbolPicker: symbolPicker,
            summaryCacheURL: directory.summaryCacheURL,
            thumbnailCacheURL: directory.thumbnailCacheURL,
            exportFolderURL: directory.exportFolderURL
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

    @Test("a recipe's file is exported as a copy of its own each time, in the export folder, under the file's name")
    func exportRecipeFile() async throws {
        try directory.makeDirectory(named: "Sauce")
        let vinaigrette = try directory.writeFile(named: "Sauce/vinaigrette.sous", "---\ntitle: Vinaigrette\n---")
        let repository = makeRepository()

        let first = try await repository.exportRecipeFile(of: vinaigrette)
        let second = try await repository.exportRecipeFile(of: vinaigrette)

        #expect(first.lastPathComponent == "vinaigrette.sous")
        #expect(first != second)
        #expect(Array(first.pathComponents.dropLast(2)) == directory.exportFolderURL.pathComponents)
        #expect(try String(contentsOf: second, encoding: .utf8) == "---\ntitle: Vinaigrette\n---")
    }

    func writeGratin(width: Int, height: Int) throws {
        try directory.writePicture(
            named: "gratin-dauphinois.png",
            width: width,
            height: height
        )
    }

    /// The picture of the file at a path, as the directory lists it now.
    func picture(at path: String) throws -> RecipePicture {
        try #require(RecipeDirectoryReader(recipeDirectory: directory.recipeDirectory).readListing().pictures[path])
    }

    @Test("a picture is read scaled to fill the box, and its thumbnail is kept outside the directory")
    func thumbnail() async throws {
        try writeGratin(width: 1_600, height: 1_000)

        let thumbnail = try await makeRepository().readThumbnail(
            of: try picture(at: "gratin-dauphinois.png"),
            filling: CGSize(width: 400.0, height: 300.0)
        )

        #expect(thumbnail.width == 481)
        #expect(thumbnail.height == 300)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).count == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.url.path()) == ["gratin-dauphinois.png"])
    }

    @Test("a picture read before is read from its thumbnail, without its file")
    func keptThumbnail() async throws {
        try writeGratin(width: 1_600, height: 1_000)
        let picture = try picture(at: "gratin-dauphinois.png")
        let box = CGSize(width: 400.0, height: 300.0)
        _ = try await makeRepository().readThumbnail(of: picture, filling: box)
        try FileManager.default.removeItem(at: directory.url.appending(path: "gratin-dauphinois.png"))

        let thumbnail = try await makeRepository().readThumbnail(of: picture, filling: box)

        #expect(thumbnail.width == 481)
    }

    @Test("a box resized a little is read from the thumbnail kept for it before, without its file")
    func resizedBox() async throws {
        try writeGratin(width: 1_600, height: 1_000)
        let picture = try picture(at: "gratin-dauphinois.png")
        _ = try await makeRepository().readThumbnail(of: picture, filling: CGSize(width: 400.0, height: 300.0))
        try FileManager.default.removeItem(at: directory.url.appending(path: "gratin-dauphinois.png"))

        let thumbnail = try await makeRepository().readThumbnail(
            of: picture,
            filling: CGSize(width: 420.0, height: 290.0)
        )

        #expect(thumbnail.width == 465)
    }

    @Test("a picture replaced since it was read is read again")
    func replacedThumbnail() async throws {
        let box = CGSize(width: 400.0, height: 300.0)
        try writeGratin(width: 1_600, height: 1_000)
        try directory.setModificationDate(.distantPast, ofFileNamed: "gratin-dauphinois.png")
        _ = try await makeRepository().readThumbnail(of: try picture(at: "gratin-dauphinois.png"), filling: box)
        try writeGratin(width: 1_000, height: 1_000)

        let replacedPicture = try picture(at: "gratin-dauphinois.png")
        let thumbnail = try await makeRepository().readThumbnail(of: replacedPicture, filling: box)

        #expect(thumbnail.width == 400)
        #expect(thumbnail.height == 400)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).count == 1)
    }

    @Test("a file holding no picture fails to read, and nothing is kept for it")
    func unreadablePicture() async throws {
        try directory.writeFile(named: "croque-monsieur.jpg", "---\ntitle: Croque Monsieur\n---")

        await #expect(throws: CocoaError.self) {
            try await self.makeRepository().readThumbnail(
                of: try self.picture(at: "croque-monsieur.jpg"),
                filling: CGSize(width: 400.0, height: 300.0)
            )
        }
        #expect(!FileManager.default.fileExists(atPath: directory.thumbnailCacheURL.path()))
    }
}
