@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe text reader", .timeLimit(.minutes(1)))
final class RecipeTextReaderTests {
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let directory: TemporaryDirectory
    private let downloads = DownloadSpy()
    private let fileStatuses = FileStatusStub()

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeTextReaderTests")
    }

    private func readText(of recipeEntry: RecipeEntry) async throws -> String {
        let reader = RecipeTextReader(recipeDirectory: directory.recipeDirectory, qualityOfService: .userInitiated)
        return try await reader.read(path: recipeEntry.path).text
    }

    /// Reads `crepes.sous` the way iCloud reports it, calling `sleep` between checks for its newest version.
    private func readCrepes(
        sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in Issue.record("waited for a newer version") }
    ) async throws -> String {
        let reader = RecipeTextReader(
            recipeDirectory: directory.recipeDirectory,
            qualityOfService: .userInitiated,
            fileStatus: fileStatuses.status,
            startDownloading: downloads.startDownloading,
            sleep: sleep
        )

        return try await reader.read(path: "crepes.sous").text
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

    @Test("a recipe outdated on the device is fetched, and read once its newest version lands")
    func outdatedRecipe() async throws {
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        fileStatuses.set(.outdated(modifiedAt: date, isDataless: false), forFileNamed: "crepes.sous")

        // The newest version lands while the reader waits for it.
        let text = try await readCrepes { [directory, fileStatuses] _ in
            try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes Suzette\n---")
            fileStatuses.set(.current(modifiedAt: nil), forFileNamed: "crepes.sous")
        }

        #expect(text == "---\ntitle: Crepes Suzette\n---")
        #expect(downloads.fileNames == ["crepes.sous"])
    }

    @Test("a recipe outdated and missing its contents is fetched and read without checking for its newest version")
    func outdatedDatalessRecipe() async throws {
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes Suzette\n---")
        fileStatuses.set(.outdated(modifiedAt: date), forFileNamed: "crepes.sous")

        let text = try await readCrepes()

        #expect(text == "---\ntitle: Crepes Suzette\n---")
        #expect(downloads.fileNames == ["crepes.sous"])
    }

    @Test("a recipe iCloud is already fetching is not asked for again")
    func recipeOnItsWay() async throws {
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes Suzette\n---")
        fileStatuses.set(.outdated(modifiedAt: date, isDownloading: true), forFileNamed: "crepes.sous")

        let text = try await readCrepes()

        #expect(text == "---\ntitle: Crepes Suzette\n---")
        #expect(downloads.fileNames.isEmpty)
    }

    @Test("a recipe current on the device is read without asking iCloud for it")
    func currentRecipe() async throws {
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        fileStatuses.set(.current(modifiedAt: date), forFileNamed: "crepes.sous")

        _ = try await readCrepes()

        #expect(downloads.fileNames.isEmpty)
    }

    @Test("a recipe that is not valid UTF-8 throws")
    func undecodableRecipe() async throws {
        try Data([0xFF, 0xFE, 0xFD]).write(to: directory.url.appending(path: "broken.sous"))

        await #expect(throws: (any Error).self) {
            try await readText(of: RecipeEntry(path: "broken.sous", availability: .downloaded))
        }
    }
}
