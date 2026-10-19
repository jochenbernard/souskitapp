@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe summarizer", .timeLimit(.minutes(1)))
final class RecipeSummarizerTests {
    private let parser = SousParser()
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let downloads = DownloadSpy()

    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeSummarizerTests")
    }

    private func makeSummarizer() -> RecipeSummarizer {
        RecipeSummarizer(
            cache: directory.summaryCache,
            parser: parser,
            textReader: RecipeTextReader(
                recipeDirectory: directory.recipeDirectory,
                qualityOfService: .utility,
                startDownloading: downloads.startDownloading
            ),
            // Every read written at once, so the cache can be checked right after.
            saveInterval: .zero
        )
    }

    private func listedFiles() throws -> [RecipeFile] {
        try RecipeDirectoryReader(recipeDirectory: directory.recipeDirectory).readListing().recipeFiles
    }

    /// Lists the directory and reads what has to be read, as the monitor does, returning the entries after.
    private func summarize(with summarizer: RecipeSummarizer) async throws -> [RecipeEntry] {
        let files = try listedFiles()
        _ = await summarizer.recipeEntries(for: files)
        await summarizer.read(await summarizer.filesToRead(in: files))

        return await summarizer.recipeEntries(for: files)
    }

    private func writeCrepes(title: String = "Crepes") throws {
        try directory.writeFile(
            named: "crepes.sous",
            "---\ntitle: \(title)\nservings: 4\n---\n\nWhisk @{200 g} flour@ with @{4} eggs@."
        )
        try directory.setModificationDate(date, ofFileNamed: "crepes.sous")
    }

    /// Keeps a summary for `crepes.sous` read from contents titled `title` and modified at `modificationDate`.
    private func cacheCrepes(title: String, modifiedAt modificationDate: Date) {
        let record = RecipeSummaryRecord(
            recipe: parser.parseRecipe("---\ntitle: \(title)\n---").value,
            modificationDate: modificationDate
        )
        directory.summaryCache.save(["crepes.sous": record])
    }

    @Test("reading on for a directory left for another writes nothing over the other's summaries")
    func leftDirectory() async throws {
        try writeCrepes()
        let summarizer = makeSummarizer()
        let files = try listedFiles()
        _ = await summarizer.recipeEntries(for: files)

        let other = try TemporaryDirectory(named: "RecipeSummarizerTests")
        let otherCache = RecipeSummaryCache(recipeDirectory: other.recipeDirectory, fileURL: directory.summaryCacheURL)
        let brioche = RecipeSummaryRecord(
            recipe: parser.parseRecipe("---\ntitle: Brioche\n---").value,
            modificationDate: date
        )
        otherCache.save(["brioche.sous": brioche])

        await summarizer.read(files)

        #expect(otherCache.load() == ["brioche.sous": brioche])
    }

    @Test("a file the cache holds nothing for is read, and its summary kept")
    func miss() async throws {
        try writeCrepes()

        let entries = try await summarize(with: makeSummarizer())

        #expect(entries.map(\.title) == ["Crepes"])
        #expect(directory.summaryCache.load()["crepes.sous"]?.modificationDate == date)
        #expect(directory.summaryCache.load()["crepes.sous"]?.ingredientNames == ["flour", "eggs"])
    }

    @Test("files sharing a name in different directories keep summaries of their own, by where they sit")
    func sameFileNameInTwoDirectories() async throws {
        try directory.makeDirectory(named: "Sauce")
        try directory.writeFile(named: "vinaigrette.sous", "---\ntitle: Vinaigrette\n---")
        try directory.writeFile(named: "Sauce/vinaigrette.sous", "---\ntitle: Vinaigrette Classic\n---")

        let entries = try await summarize(with: makeSummarizer())

        #expect(entries.map(\.title) == ["Vinaigrette Classic", "Vinaigrette"])
        #expect(Set(directory.summaryCache.load().keys) == ["Sauce/vinaigrette.sous", "vinaigrette.sous"])
    }

    @Test("a file unchanged since its summary was kept is listed from the cache, not read")
    func hit() async throws {
        try writeCrepes()
        cacheCrepes(title: "Crepes Suzette", modifiedAt: date)
        let summarizer = makeSummarizer()

        let files = try listedFiles()

        #expect(await summarizer.recipeEntries(for: files).map(\.title) == ["Crepes Suzette"])
        #expect(await summarizer.filesToRead(in: files).isEmpty)
    }

    @Test("a file changed since its summary was kept is read again")
    func changedDate() async throws {
        try writeCrepes()
        cacheCrepes(title: "Crepes Suzette", modifiedAt: date.addingTimeInterval(-60.0))
        let summarizer = makeSummarizer()

        // The summary read before stands in until the new one lands.
        #expect(await summarizer.recipeEntries(for: try listedFiles()).map(\.title) == ["Crepes Suzette"])
        #expect(try await summarize(with: summarizer).map(\.title) == ["Crepes"])
    }

    @Test("the summary of a file removed from the directory is dropped")
    func removedFile() async throws {
        try writeCrepes()
        let summarizer = makeSummarizer()
        _ = try await summarize(with: summarizer)

        try FileManager.default.removeItem(at: directory.url.appending(path: "crepes.sous"))
        let entries = try await summarize(with: summarizer)

        #expect(entries.isEmpty)
        #expect(directory.summaryCache.load().isEmpty)
    }

    @Test("after the system clears the cache, a new launch reads every file again")
    func clearedCache() async throws {
        try writeCrepes()
        _ = try await summarize(with: makeSummarizer())

        try FileManager.default.removeItem(at: directory.summaryCacheURL)
        let summarizer = makeSummarizer()

        #expect(await summarizer.recipeEntries(for: try listedFiles()).map(\.summary) == [nil])
        #expect(try await summarize(with: summarizer).map(\.title) == ["Crepes"])
    }

    @Test("a file the cache knows nothing of and that is not read yet is listed by its name")
    func unreadFile() async throws {
        try writeCrepes()

        let entries = await makeSummarizer().recipeEntries(for: try listedFiles())

        #expect(entries.map(\.title) == ["crepes"])
    }

    @Test("a file on the device is read without asking iCloud for it")
    func downloadedFileIsNotFetched() async throws {
        try writeCrepes()

        _ = try await summarize(with: makeSummarizer())

        #expect(downloads.fileNames.isEmpty)
    }

    @Test("a recipe in iCloud the cache holds nothing for is fetched")
    func newPlaceholderIsFetched() async throws {
        try directory.writeFile(named: ".crepes.sous.icloud")

        _ = try await summarize(with: makeSummarizer())

        #expect(downloads.fileNames == ["crepes.sous"])
    }

    @Test("a recipe in iCloud whose summary is kept stays in iCloud")
    func cachedPlaceholderStays() async throws {
        try directory.writeFile(named: ".crepes.sous.icloud")
        cacheCrepes(title: "Crepes", modifiedAt: date)

        let entries = try await summarize(with: makeSummarizer())

        #expect(entries.map(\.title) == ["Crepes"])
        #expect(entries.map(\.availability) == [.notDownloaded])
        #expect(downloads.fileNames.isEmpty)
    }

    @Test("a recipe in iCloud changed since its summary was kept is fetched")
    func changedPlaceholderIsFetched() async {
        cacheCrepes(title: "Crepes", modifiedAt: date)
        let summarizer = makeSummarizer()
        let file = RecipeFile(
            path: "crepes.sous",
            availability: .notDownloaded,
            modificationDate: date.addingTimeInterval(60.0)
        )

        await summarizer.read(await summarizer.filesToRead(in: [file]))

        #expect(downloads.fileNames == ["crepes.sous"])
    }

    @Test("a recipe in iCloud unchanged since its summary was kept is not fetched")
    func unchangedEvictedFileStays() async {
        cacheCrepes(title: "Crepes", modifiedAt: date)
        let summarizer = makeSummarizer()
        let file = RecipeFile(
            path: "crepes.sous",
            availability: .notDownloaded,
            modificationDate: date
        )

        #expect(await summarizer.filesToRead(in: [file]).isEmpty)
        #expect(downloads.fileNames.isEmpty)
    }
}
