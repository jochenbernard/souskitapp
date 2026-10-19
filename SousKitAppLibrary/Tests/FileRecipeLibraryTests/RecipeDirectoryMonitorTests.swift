@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe directory monitor", .timeLimit(.minutes(1)))
final class RecipeDirectoryMonitorTests: Sendable {
    let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDirectoryMonitorTests")
    }

    func makeMonitor() -> RecipeDirectoryMonitor {
        RecipeDirectoryMonitor(
            recipeDirectory: directory.recipeDirectory,
            summarizer: RecipeSummarizer(
                cache: directory.summaryCache,
                parser: SousParser(),
                textReader: RecipeTextReader(recipeDirectory: directory.recipeDirectory, qualityOfService: .utility)
            ),
            settleDelay: .milliseconds(20)
        )
    }

    /// A monitor over `count` recipes all in iCloud, which the stub fetches.
    private func makeICloudMonitor(
        count: Int,
        iCloud: (([String: String]) -> ICloudStub),
        cacheWrites: CacheWriteSpy
    ) throws -> (RecipeDirectoryMonitor, ICloudStub) {
        let fileNames = (1...count).map({ "recipe-\($0).sous" })
        try fileNames.forEach({ try directory.writeFile(named: ".\($0).icloud") })
        let stub = iCloud(Dictionary(uniqueKeysWithValues: fileNames.map({ ($0, "---\ntitle: \($0)\n---") })))

        let monitor = RecipeDirectoryMonitor(
            recipeDirectory: directory.recipeDirectory,
            summarizer: RecipeSummarizer(
                cache: RecipeSummaryCache(
                    recipeDirectory: directory.recipeDirectory,
                    fileURL: directory.summaryCacheURL,
                    write: cacheWrites.write
                ),
                parser: SousParser(),
                textReader: RecipeTextReader(
                    recipeDirectory: directory.recipeDirectory,
                    qualityOfService: .utility,
                    startDownloading: stub.startDownloading
                )
            ),
            settleDelay: .milliseconds(20)
        )

        return (monitor, stub)
    }

    /// Whether the monitor reaches the given names, reading on until it does or the suite's time
    /// limit ends the test.
    ///
    /// The monitor is taken as a parameter so that it outlives the stream it vends; a caller that
    /// released it would see the stream end before the list arrives.
    @MainActor
    private func names(
        reach expected: [String],
        from monitor: RecipeDirectoryMonitor,
        whileChanging change: () throws -> Void = {}
    ) async throws -> Bool {
        let stream = monitor.listedRecipes()
        try change()

        for await result in stream where (try? result.get())?.map(\.entry.name) == expected {
            return true
        }

        return false
    }

    /// The first result the monitor reaches.
    @MainActor
    private func firstResult(
        from monitor: RecipeDirectoryMonitor
    ) async -> Result<[ListedRecipe], Error>? {
        for await result in monitor.listedRecipes() {
            return result
        }

        return nil
    }

    @MainActor
    @Test("the recipes already there arrive first")
    func firstRead() async throws {
        try directory.writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["crepes"], from: makeMonitor())

        #expect(reached)
    }

    @MainActor
    @Test("an empty directory arrives as no recipes")
    func emptyDirectory() async throws {
        let reached = try await names(reach: [], from: makeMonitor())

        #expect(reached)
    }

    @MainActor
    @Test("a directory that is gone arrives as a failure")
    func failingRead() async throws {
        try FileManager.default.removeItem(at: directory.url)

        let result = await firstResult(from: makeMonitor())

        #expect(throws: (any Error).self) {
            try #require(result).get()
        }
    }

    @MainActor
    @Test("a recipe added to the directory arrives")
    func addedRecipe() async throws {
        try directory.writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["brioche", "crepes"], from: makeMonitor()) {
            try directory.writeFile(named: "brioche.sous")
        }

        #expect(reached)
    }

    @MainActor
    @Test("a recipe removed from the directory stops arriving")
    func removedRecipe() async throws {
        try directory.writeFile(named: "crepes.sous")
        try directory.writeFile(named: "brioche.sous")

        let reached = try await names(reach: ["crepes"], from: makeMonitor()) {
            try FileManager.default.removeItem(at: directory.url.appending(path: "brioche.sous"))
        }

        #expect(reached)
    }

    @MainActor
    @Test("a recipe renamed in the directory arrives under the new name")
    func renamedRecipe() async throws {
        try directory.writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["crepes suzette"], from: makeMonitor()) {
            try FileManager.default.moveItem(
                at: directory.url.appending(path: "crepes.sous"),
                to: directory.url.appending(path: "crepes-suzette.sous")
            )
        }

        #expect(reached)
    }

    @MainActor
    @Test("refreshing reaches the recipes written since the last read")
    func refreshing() async throws {
        let monitor = makeMonitor()

        let reached = try await names(reach: ["crepes"], from: monitor) {
            try directory.writeFile(named: "crepes.sous")
            monitor.refresh()
        }

        #expect(reached)
    }

    @MainActor
    @Test("a launch lists the recipes before reading any, then again with what was read")
    func coldCache() async throws {
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        let monitor = makeMonitor()
        var titles: [[String]] = []

        for await result in monitor.listedRecipes() {
            titles.append(try result.get().map(\.entry.title))

            if titles.count == 2 {
                break
            }
        }

        #expect(titles == [["crepes"], ["Crepes"]])
    }

    @MainActor
    @Test("a launch with the summaries kept lists them first, reading nothing")
    func warmCache() async throws {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        try directory.setModificationDate(date, ofFileNamed: "crepes.sous")
        directory.summaryCache.save([
            "crepes.sous": RecipeSummaryRecord(
                recipe: SousParser().parseRecipe("---\ntitle: Crepes Suzette\n---").value,
                modificationDate: date
            )
        ])

        let result = await firstResult(from: makeMonitor())

        #expect(try #require(result).get().map(\.entry.title) == ["Crepes Suzette"])
    }

    @MainActor
    @Test("a first launch over recipes in iCloud fetches each once, and writes the cache once a second at most")
    func iCloudLaunch() async throws {
        let cacheWrites = CacheWriteSpy()
        let (monitor, iCloud) = try makeICloudMonitor(
            count: 50,
            iCloud: { ICloudStub(texts: $0, interval: 0.06) },
            cacheWrites: cacheWrites
        )
        let start = ContinuousClock.now

        for await result in monitor.listedRecipes() where try result.get().allSatisfy({ $0.entry.summary != nil }) {
            break
        }

        let seconds = Int((ContinuousClock.now - start) / .seconds(1))

        #expect(iCloud.requests.count == 50)
        #expect(iCloud.requests.values.allSatisfy({ $0 == 1 }))
        #expect(cacheWrites.count <= seconds + 2)
    }

    @MainActor
    @Test("the summaries of recipes landing from iCloud are kept within a second, while the rest are on their way")
    func iCloudLaunchKeepsWhatLanded() async throws {
        let (monitor, _) = try makeICloudMonitor(
            count: 50,
            iCloud: { ICloudStub(texts: $0, interval: 0.06) },
            cacheWrites: CacheWriteSpy()
        )
        var landed = 0
        var kept = 0

        for await result in monitor.listedRecipes() {
            landed = try result.get().count(where: { $0.entry.summary != nil })

            if landed >= 10 {
                try await Task.sleep(for: .seconds(1.2))
                kept = directory.summaryCache.load().count
                break
            }
        }

        #expect(kept >= landed)
        #expect(kept < 50)
    }

    @MainActor
    @Test("a second stream ends the first")
    func secondStream() async throws {
        let monitor = makeMonitor()
        let first = monitor.listedRecipes()

        let reached = try await names(reach: [], from: monitor)

        var firstResults: [Result<[ListedRecipe], Error>] = []
        for await result in first {
            firstResults.append(result)
        }

        #expect(reached)
        #expect(firstResults.isEmpty)
    }
}
