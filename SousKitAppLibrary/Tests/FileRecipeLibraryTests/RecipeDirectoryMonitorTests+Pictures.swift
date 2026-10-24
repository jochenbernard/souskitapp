import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

extension RecipeDirectoryMonitorTests {
    /// The pictures of the recipes the monitor lists, by recipe name, once they match what is expected, or nothing
    /// before the suite's time limit ends the test.
    ///
    /// - Parameters:
    ///   - monitor: The monitor, taken as a parameter so that it outlives the stream it vends.
    ///   - change: A change to make once the recipes are first listed.
    ///   - isExpected: Whether the pictures listed are the ones waited for.
    @MainActor
    private func pictures(
        from monitor: RecipeDirectoryMonitor,
        afterListing change: () throws -> Void = {},
        until isExpected: ([String: RecipePicture?]) -> Bool
    ) async throws -> [String: RecipePicture?] {
        var hasChanged = false

        for await result in monitor.listedRecipes() {
            let pictures = Dictionary(
                uniqueKeysWithValues: try result.get().map({ ($0.entry.name, $0.entry.picture) })
            )

            if isExpected(pictures) {
                return pictures
            }

            if !hasChanged {
                hasChanged = true
                try change()
            }
        }

        return [:]
    }

    private func writeRecipe(named name: String, naming imagePath: String) throws {
        try directory.writeFile(named: "\(name).sous", "---\ntitle: \(name)\nimage: \(imagePath)\n---")
    }

    @MainActor
    @Test("a recipe lists the picture its header names where the directory holds it, and no picture where it does not")
    func namedPictures() async throws {
        try directory.makeDirectory(named: "images")
        try writeRecipe(named: "crepes", naming: "images/crepes.jpg")
        try writeRecipe(named: "brioche", naming: "images/brioche.jpg")
        try writeRecipe(named: "madeleines", naming: "../images/crepes.jpg")
        try directory.writeFile(named: "images/crepes.jpg")

        let pictures = try await pictures(from: makeMonitor()) { pictures in
            pictures["crepes"]??.id == "images/crepes.jpg"
        }

        #expect(pictures["brioche"] == .some(nil))
        #expect(pictures["madeleines"] == .some(nil))
    }

    @MainActor
    @Test("a picture in iCloud that a recipe names is fetched once, and one on the device or named by none is not")
    func picturesFetchedFromICloud() async throws {
        let downloads = DownloadSpy()
        try directory.makeDirectory(named: "images")
        try writeRecipe(named: "crepes", naming: "images/crepes.jpg")
        try writeRecipe(named: "brioche", naming: "images/brioche.jpg")
        try directory.writeFile(named: "images/.crepes.jpg.icloud")
        try directory.writeFile(named: "images/brioche.jpg")
        try directory.writeFile(named: "images/.madeleines.jpg.icloud")
        let monitor = makeMonitor(pictureDownloads: downloads)

        _ = try await pictures(from: monitor) { pictures in
            pictures["crepes"]??.availability == .notDownloaded
        }
        // Long enough for the fetch to end and the directory to be read again after it.
        try await Task.sleep(for: .milliseconds(500))

        #expect(downloads.fileNames == ["crepes.jpg"])
    }

    @MainActor
    @Test("a picture replaced in its directory reaches the recipe naming it, under its new date")
    func replacedPicture() async throws {
        let oldDate = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        try directory.makeDirectory(named: "images")
        try writeRecipe(named: "crepes", naming: "images/crepes.jpg")
        try directory.writeFile(named: "images/crepes.jpg")
        try directory.setModificationDate(oldDate, ofFileNamed: "images/crepes.jpg")

        let pictures = try await pictures(
            from: makeMonitor(),
            afterListing: {
                try Data([1]).write(to: directory.url.appending(path: "images/crepes.jpg"), options: .atomic)
            },
            until: { pictures in
                guard let date = pictures["crepes"]??.modificationDate else {
                    return false
                }

                return date != oldDate
            }
        )

        #expect(pictures["crepes"]??.id == "images/crepes.jpg")
    }

    @MainActor
    @Test("the thumbnails of a picture no recipe names any more are removed, and those of a named one stay")
    func unnamedPictureThumbnails() async throws {
        let cache = RecipeThumbnailCache(
            recipeDirectory: directory.recipeDirectory,
            folderURL: directory.thumbnailCacheURL
        )
        let box = CGSize(width: 480.0, height: 360.0)
        try directory.makeDirectory(named: "images")
        try writeRecipe(named: "crepes", naming: "images/crepes.jpg")
        try writeRecipe(named: "brioche", naming: "images/brioche.jpg")
        try directory.writeFile(named: "images/crepes.jpg")
        try directory.writeFile(named: "images/brioche.jpg")
        let monitor = makeMonitor(thumbnailCache: cache)

        let listed = try await pictures(from: monitor) { pictures in
            pictures["crepes"]??.id != nil && pictures["brioche"]??.id != nil
        }
        let crepes = try #require(listed["crepes"] as? RecipePicture)
        let brioche = try #require(listed["brioche"] as? RecipePicture)
        let thumbnail = try TemporaryDirectory.picture(
            width: 480,
            height: 360,
            gray: 0.5
        )
        cache.save(
            thumbnail,
            of: crepes,
            filling: box
        )
        cache.save(
            thumbnail,
            of: brioche,
            filling: box
        )

        _ = try await pictures(
            from: monitor,
            afterListing: { try writeRecipe(named: "brioche", naming: "https://example.com/brioche.jpg") },
            until: { pictures in pictures["brioche"] == .some(nil) }
        )
        // Long enough for the removal, which runs off the main actor, to end.
        try await Task.sleep(for: .milliseconds(500))

        #expect(cache.thumbnail(of: crepes, filling: box) != nil)
        #expect(cache.thumbnail(of: brioche, filling: box) == nil)
    }
}
