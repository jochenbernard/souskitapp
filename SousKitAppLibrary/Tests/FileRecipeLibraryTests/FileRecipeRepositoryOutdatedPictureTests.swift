import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("File recipe repository over pictures outdated on the device", .timeLimit(.minutes(1)))
final class FileRecipeRepositoryOutdatedPictureTests: Sendable {
    private let box = CGSize(width: 400.0, height: 300.0)
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let directory: TemporaryDirectory
    private let downloads = DownloadSpy()
    private let fileStatuses = FileStatusStub()
    private let laterDate = Date(timeIntervalSinceReferenceDate: 800_000_600.0)

    init() throws {
        self.directory = try TemporaryDirectory(named: "FileRecipeRepositoryOutdatedPictureTests")
    }

    /// A repository over a recipe naming `gratin-dauphinois.png`, a landscape picture at `date`.
    private func makeRepository() throws -> FileRecipeRepository {
        try directory.writeFile(named: "gratin.sous", "---\ntitle: Gratin\nimage: gratin-dauphinois.png\n---")
        try directory.writePicture(
            named: "gratin-dauphinois.png",
            width: 1_600,
            height: 1_000
        )
        try directory.setModificationDate(date, ofFileNamed: "gratin-dauphinois.png")

        return FileRecipeRepository(
            parser: SousParser(),
            recipeDirectory: directory.recipeDirectory,
            symbolPicker: RecipeSymbolPickerStub(isAvailable: false),
            summaryCacheURL: directory.summaryCacheURL,
            thumbnailCacheURL: directory.thumbnailCacheURL,
            fileStatus: fileStatuses.status,
            startDownloading: downloads.startDownloading
        )
    }

    /// Reads on until the gratin's picture is listed as `isDone` expects, or the suite's time limit ends the test.
    @MainActor
    private func gratinPicture(
        from results: inout AsyncStream<Result<[ListedRecipe], Error>>.Iterator,
        until isDone: (RecipePicture) -> Bool
    ) async throws -> RecipePicture {
        while let result = await results.next(isolation: #isolation) {
            if let picture = try result.get().first?.entry.picture, isDone(picture) {
                return picture
            }
        }

        Issue.record("The stream ended before the picture was listed.")
        throw CancellationError()
    }

    /// The thumbnails kept, by name.
    private func keptThumbnails() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path())
    }

    @MainActor
    @Test("a picture outdated at an unchanged date is fetched once, its kept thumbnail read until the newer one lands")
    func outdatedPicture() async throws {
        let repository = try makeRepository()
        fileStatuses.set(.current(modifiedAt: date), forFileNamed: "gratin-dauphinois.png")
        var results = await repository.listedRecipes().makeAsyncIterator()
        let picture = try await gratinPicture(from: &results, until: { $0.availability == .downloaded })
        _ = try await repository.readThumbnail(of: picture, filling: box)

        // The newer version waits in iCloud, the older one still on the device.
        fileStatuses.set(.outdated(modifiedAt: date, isDataless: false), forFileNamed: "gratin-dauphinois.png")
        await repository.refresh()
        let outdatedPicture = try await gratinPicture(from: &results, until: { $0.availability == .downloading })

        while downloads.fileNames.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let keptThumbnail = try await repository.readThumbnail(of: outdatedPicture, filling: box)

        try directory.writePicture(
            named: "gratin-dauphinois.png",
            width: 1_000,
            height: 1_000
        )
        try directory.setModificationDate(laterDate, ofFileNamed: "gratin-dauphinois.png")
        fileStatuses.set(.current(modifiedAt: laterDate), forFileNamed: "gratin-dauphinois.png")
        let landedPicture = try await gratinPicture(from: &results, until: { $0.modificationDate == laterDate })
        let replacedThumbnail = try await repository.readThumbnail(of: landedPicture, filling: box)

        #expect(outdatedPicture.modificationDate == date)
        #expect(keptThumbnail.width == 481)
        #expect(landedPicture.availability == .downloaded)
        #expect(replacedThumbnail.width == 400)
        #expect(replacedThumbnail.height == 400)
        #expect(try keptThumbnails().count == 1)
        #expect(downloads.fileNames == ["gratin-dauphinois.png"])
    }

    @MainActor
    @Test("a picture current on the device at an unchanged date is not fetched again")
    func currentPicture() async throws {
        let repository = try makeRepository()
        fileStatuses.set(.current(modifiedAt: date), forFileNamed: "gratin-dauphinois.png")
        var results = await repository.listedRecipes().makeAsyncIterator()
        let picture = try await gratinPicture(from: &results, until: { $0.availability == .downloaded })
        _ = try await repository.readThumbnail(of: picture, filling: box)

        await repository.refresh()
        // Long enough for the directory to be read again, and for a fetch it started to be asked for.
        try await Task.sleep(for: .milliseconds(500))
        let thumbnail = try await repository.readThumbnail(of: picture, filling: box)

        #expect(thumbnail.width == 481)
        #expect(downloads.fileNames.isEmpty)
    }
}
