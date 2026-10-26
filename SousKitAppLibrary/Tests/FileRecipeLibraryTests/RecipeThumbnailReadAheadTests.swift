import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe thumbnail read ahead", .timeLimit(.minutes(1)))
final class RecipeThumbnailReadAheadTests {
    private let box = CGSize(width: 480.0, height: 360.0)
    private let directory: TemporaryDirectory
    private let modificationDate = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeThumbnailReadAheadTests")
    }

    private func makeCache() -> RecipeThumbnailCache {
        RecipeThumbnailCache(recipeDirectory: directory.recipeDirectory, folderURL: directory.thumbnailCacheURL)
    }

    private func picture(_ name: String) -> RecipePicture {
        RecipePicture(
            id: "images/\(name).jpg",
            modificationDate: modificationDate,
            availability: .downloaded
        )
    }

    /// A recipe listed with the picture of its own name.
    private func entry(_ name: String, in folderPath: [String] = []) -> RecipeEntry {
        RecipeEntry(
            id: (folderPath + ["\(name).sous"]).joined(separator: "/"),
            name: name,
            availability: .downloaded,
            folderPath: folderPath,
            picture: picture(name)
        )
    }

    /// Keeps a thumbnail of each picture, read for the box.
    private func keep(_ pictures: [RecipePicture]) throws {
        let thumbnail = try TemporaryDirectory.picture(
            width: 480,
            height: 360,
            gray: 0.5
        )

        for picture in pictures {
            makeCache().save(
                thumbnail,
                of: picture,
                filling: box
            )
        }
    }

    /// A read ahead started on a listing of recipes.
    private func readAhead(of entries: [RecipeEntry]) -> RecipeThumbnailReadAhead {
        let readAhead = RecipeThumbnailReadAhead()
        let listing = Task<[ListedRecipe], Error> {
            entries.map({ ListedRecipe(entry: $0, ingredientNames: []) })
        }
        readAhead.start(after: listing, from: makeCache())

        return readAhead
    }

    @Test("the pictures shown first are those each folder's card stacks, its own recipes first, then those at the top")
    func firstPictures() {
        let entries = [
            entry("boeuf-bourguignon"),
            entry("brioche", in: ["Baking", "Breads"]),
            entry("crepes", in: ["Baking"]),
            entry("croque-monsieur", in: ["Lunch"]),
            entry("madeleines", in: ["Baking"]),
            entry("quiche-lorraine", in: ["Baking"]),
            entry("gratin-dauphinois", in: ["Baking"]),
            entry("vinaigrette")
        ]

        let pictures = RecipeThumbnailReadAhead.firstPictures(of: entries)

        #expect(
            pictures.map(\.id) == [
                "images/crepes.jpg",
                "images/madeleines.jpg",
                "images/quiche-lorraine.jpg",
                "images/gratin-dauphinois.jpg",
                "images/croque-monsieur.jpg",
                "images/boeuf-bourguignon.jpg",
                "images/vinaigrette.jpg"
            ]
        )
    }

    @Test("at most 24 pictures are shown first, and a recipe naming none adds none")
    func firstPictureLimit() {
        let unpictured = RecipeEntry(
            id: "bouillabaisse.sous",
            name: "bouillabaisse",
            availability: .downloaded
        )
        let entries = [unpictured] + (1...30).map({ entry("crepes-\($0)") })

        let pictures = RecipeThumbnailReadAhead.firstPictures(of: entries)

        #expect(pictures.map(\.id) == (1...24).map({ "images/crepes-\($0).jpg" }))
    }

    @Test("the thumbnails kept for the pictures shown first are read once the listing lands, and each handed out once")
    func handedOutOnce() async throws {
        let crepes = picture("crepes")
        let brioche = picture("brioche")
        try keep([crepes, brioche])
        let readAhead = readAhead(of: [entry("crepes"), entry("brioche")])

        #expect(await readAhead.thumbnail(of: crepes) != nil)

        // Read ahead already, so it no longer needs the thumbnail kept.
        try FileManager.default.removeItem(at: directory.thumbnailCacheURL)

        #expect(await readAhead.thumbnail(of: brioche) != nil)
        #expect(await readAhead.thumbnail(of: brioche) == nil)
        #expect(await readAhead.thumbnail(of: crepes) == nil)
    }

    @Test("a picture with no thumbnail kept, or listed with another date, is handed out none, and nothing is written")
    func noThumbnail() async throws {
        let crepes = picture("crepes")
        try keep([crepes])
        let readAhead = readAhead(of: [entry("crepes"), entry("brioche")])
        let replacedCrepes = RecipePicture(
            id: crepes.id,
            modificationDate: modificationDate.addingTimeInterval(60.0),
            availability: .downloaded
        )

        #expect(await readAhead.thumbnail(of: picture("brioche")) == nil)
        #expect(await readAhead.thumbnail(of: replacedCrepes) == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).count == 1)
    }

    @Test("a read ahead never started, or whose listing fails, hands out none")
    func noListing() async throws {
        let crepes = picture("crepes")
        try keep([crepes])
        let failingReadAhead = RecipeThumbnailReadAhead()
        failingReadAhead.start(
            after: Task<[ListedRecipe], Error>(operation: { throw CocoaError(.fileReadUnknown) }),
            from: makeCache()
        )

        #expect(await RecipeThumbnailReadAhead().thumbnail(of: crepes) == nil)
        #expect(await failingReadAhead.thumbnail(of: crepes) == nil)
    }
}
