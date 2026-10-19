import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe thumbnail cache")
final class RecipeThumbnailCacheTests {
    private let directory: TemporaryDirectory
    private let modificationDate = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let pixelSize = CGSize(width: 480.0, height: 360.0)

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeThumbnailCacheTests")
    }

    private func makeCache() -> RecipeThumbnailCache {
        RecipeThumbnailCache(recipeDirectory: directory.recipeDirectory, folderURL: directory.thumbnailCacheURL)
    }

    private func picture(modifiedAt date: Date?) -> RecipePicture {
        RecipePicture(
            id: "images/gratin-dauphinois.jpg",
            modificationDate: date,
            availability: .downloaded
        )
    }

    /// Keeps a thumbnail of one shade of gray for the picture as it was modified at a date.
    private func keep(gray: Double, modifiedAt date: Date?) throws {
        let thumbnail = try TemporaryDirectory.picture(
            width: 480,
            height: 360,
            gray: gray
        )

        makeCache().save(
            thumbnail,
            of: picture(modifiedAt: date),
            filling: pixelSize
        )
    }

    /// The thumbnail kept for the picture as it was modified at a date, read by a cache made afresh.
    private func kept(modifiedAt date: Date?, filling size: CGSize? = nil) -> CGImage? {
        makeCache().thumbnail(of: picture(modifiedAt: date), filling: size ?? pixelSize)
    }

    /// The shade of gray in the middle of a thumbnail, from 0 to 255.
    private func shade(of image: CGImage) throws -> UInt8 {
        let data = try #require(image.dataProvider?.data as Data?)
        let middle = (image.height / 2) * image.bytesPerRow + (image.width / 2) * (image.bitsPerPixel / 8)

        return data[middle]
    }

    @Test("a thumbnail kept is read back for its picture at its size")
    func hit() throws {
        try keep(gray: 0.2, modifiedAt: modificationDate)

        let read = try #require(kept(modifiedAt: modificationDate))

        #expect(read.width == 480)
        #expect(read.height == 360)
    }

    @Test("a picture never kept, or kept at another size, is not found")
    func miss() throws {
        #expect(kept(modifiedAt: modificationDate) == nil)

        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(kept(modifiedAt: modificationDate, filling: CGSize(width: 240.0, height: 180.0)) == nil)
    }

    @Test("a picture replaced since is not found under its new date, and its new thumbnail is kept beside")
    func replacedPicture() throws {
        let replacedDate = modificationDate.addingTimeInterval(60.0)
        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(kept(modifiedAt: replacedDate) == nil)

        try keep(gray: 0.9, modifiedAt: replacedDate)

        #expect(try shade(of: try #require(kept(modifiedAt: replacedDate))) > 200)
        #expect(try shade(of: try #require(kept(modifiedAt: modificationDate))) < 100)
    }

    @Test("a cache the system cleared finds nothing, and keeps thumbnails again")
    func clearedCache() throws {
        try keep(gray: 0.2, modifiedAt: modificationDate)
        try FileManager.default.removeItem(at: directory.thumbnailCacheURL)

        #expect(kept(modifiedAt: modificationDate) == nil)

        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(kept(modifiedAt: modificationDate) != nil)
    }

    @Test("a picture telling no date is never kept, since it could never be told apart from its replacement")
    func noDate() throws {
        try keep(gray: 0.2, modifiedAt: nil)

        #expect(kept(modifiedAt: nil) == nil)
        #expect(!FileManager.default.fileExists(atPath: directory.thumbnailCacheURL.path()))
    }

    @Test("thumbnails are kept outside the recipe directory")
    func outsideTheDirectory() throws {
        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.url.path()).isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).count == 1)
    }
}
