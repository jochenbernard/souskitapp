@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe picture reader", .timeLimit(.minutes(1)))
final class RecipePictureReaderTests {
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let directory: TemporaryDirectory
    private let downloads = DownloadSpy()
    private let fileStatuses = FileStatusStub()

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipePictureReaderTests")
    }

    /// Reads `crepes.jpg` the way iCloud reports it, calling `sleep` between checks for its newest version.
    private func readCrepes(
        listedAs availability: RecipeAvailability = .downloaded,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in Issue.record("waited for a newer version") }
    ) async throws -> String {
        let reader = RecipePictureReader(
            recipeDirectory: directory.recipeDirectory,
            qualityOfService: .userInitiated,
            fileStatus: fileStatuses.status,
            startDownloading: downloads.startDownloading,
            sleep: sleep
        )
        let picture = RecipePicture(
            id: "crepes.jpg",
            modificationDate: date,
            availability: availability
        )

        return try await reader.read(picture) { url in
            try String(contentsOf: url, encoding: .utf8)
        }
    }

    @Test("a picture outdated on the device is fetched, and read once its newest version lands, however it is listed")
    func outdatedPicture() async throws {
        try directory.writeFile(named: "crepes.jpg", "older")
        fileStatuses.set(.outdated(modifiedAt: date, isDataless: false), forFileNamed: "crepes.jpg")

        // The newest version lands while the reader waits for it.
        let contents = try await readCrepes { [directory, fileStatuses] _ in
            try directory.writeFile(named: "crepes.jpg", "newer")
            fileStatuses.set(.current(modifiedAt: nil), forFileNamed: "crepes.jpg")
        }

        #expect(contents == "newer")
        #expect(downloads.fileNames == ["crepes.jpg"])
    }

    @Test("a picture iCloud is already fetching is not asked for again")
    func pictureOnItsWay() async throws {
        try directory.writeFile(named: "crepes.jpg", "newer")
        fileStatuses.set(.outdated(modifiedAt: date, isDownloading: true), forFileNamed: "crepes.jpg")

        let contents = try await readCrepes(listedAs: .downloading)

        #expect(contents == "newer")
        #expect(downloads.fileNames.isEmpty)
    }

    @Test("a picture current on the device is read without asking iCloud for it, however it is listed")
    func currentPicture() async throws {
        try directory.writeFile(named: "crepes.jpg", "newer")
        fileStatuses.set(.current(modifiedAt: date), forFileNamed: "crepes.jpg")

        _ = try await readCrepes(listedAs: .notDownloaded)

        #expect(downloads.fileNames.isEmpty)
    }
}
