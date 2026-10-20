@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe directory monitor over recipes outdated on the device", .timeLimit(.minutes(1)))
final class RecipeDirectoryMonitorOutdatedTests: Sendable {
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let directory: TemporaryDirectory
    private let iCloud = ICloudStub(texts: ["crepes.sous": "---\ntitle: Crepes Suzette\n---"])

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeDirectoryMonitorOutdatedTests")
    }

    /// A monitor over `crepes.sous`, summarized and outdated at `date` until the stub lands its newer version.
    private func makeMonitor() throws -> RecipeDirectoryMonitor {
        let parser = SousParser()
        try directory.writeFile(named: "crepes.sous", "---\ntitle: Crepes\n---")
        try directory.setModificationDate(date, ofFileNamed: "crepes.sous")
        directory.summaryCache.save([
            "crepes.sous": RecipeSummaryRecord(
                recipe: parser.parseRecipe("---\ntitle: Crepes\n---").value,
                modificationDate: date
            )
        ])

        // Landing the newer version changes the file's date.
        let fileStatus: @Sendable (URL) -> RecipeFileStatus? = { [date] url in
            let status = RecipeFileStatus.read(at: url)

            guard url.lastPathComponent == "crepes.sous", status?.modificationDate == date else {
                return status
            }

            return .outdated(modifiedAt: date)
        }

        return RecipeDirectoryMonitor(
            recipeDirectory: directory.recipeDirectory,
            summarizer: RecipeSummarizer(
                cache: directory.summaryCache,
                parser: parser,
                textReader: RecipeTextReader(
                    recipeDirectory: directory.recipeDirectory,
                    qualityOfService: .utility,
                    fileStatus: fileStatus,
                    startDownloading: iCloud.startDownloading
                )
            ),
            settleDelay: .milliseconds(20),
            fileStatus: fileStatus
        )
    }

    /// Reads on until `isDone` holds for a list of recipes, or the suite's time limit ends the test.
    ///
    /// - Returns: The entries of `crepes.sous` in the lists read.
    @MainActor
    private func readCrepes(
        from results: inout AsyncStream<Result<[ListedRecipe], Error>>.Iterator,
        until isDone: ([RecipeEntry]) -> Bool
    ) async throws -> [RecipeEntry] {
        var crepes: [RecipeEntry] = []

        while let result = await results.next(isolation: #isolation) {
            let recipeEntries = try result.get().map(\.entry)
            crepes += recipeEntries.filter({ $0.path == "crepes.sous" })

            if isDone(recipeEntries) {
                break
            }
        }

        return crepes
    }

    @MainActor
    @Test("an outdated recipe is fetched once and read again unopened, keeping its summary meanwhile")
    func outdatedRecipe() async throws {
        let monitor = try makeMonitor()
        var results = monitor.listedRecipes().makeAsyncIterator()

        while iCloud.requests.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        // Another listing while the fetch is on its way, which asks for nothing more.
        try directory.writeFile(named: "brioche.sous", "---\ntitle: Brioche\n---")
        var crepes = try await readCrepes(from: &results) { recipeEntries in
            recipeEntries.contains(where: { $0.title == "Brioche" })
        }

        iCloud.land(["crepes.sous"])
        crepes += try await readCrepes(from: &results) { recipeEntries in
            recipeEntries.contains(where: { $0.title == "Crepes Suzette" && $0.availability == .downloaded })
        }

        // Never the file's name in between.
        #expect(Set(crepes.map(\.title)) == ["Crepes", "Crepes Suzette"])
        #expect(crepes.filter({ $0.title == "Crepes" }).allSatisfy({ $0.availability == .downloading }))
        #expect(iCloud.requests == ["crepes.sous": 1])
    }
}
