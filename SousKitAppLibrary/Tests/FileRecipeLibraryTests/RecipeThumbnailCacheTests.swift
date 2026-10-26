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
    private func keep(
        gray: Double,
        modifiedAt date: Date?,
        filling size: CGSize? = nil
    ) throws {
        let thumbnail = try TemporaryDirectory.picture(
            width: 480,
            height: 360,
            gray: gray
        )

        makeCache().save(
            thumbnail,
            of: picture(modifiedAt: date),
            filling: size ?? pixelSize
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

    @Test("a picture replaced since is not found under its new date, and its new thumbnail takes the old one's place")
    func replacedPicture() throws {
        let replacedDate = modificationDate.addingTimeInterval(60.0)
        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(kept(modifiedAt: replacedDate) == nil)

        try keep(gray: 0.9, modifiedAt: replacedDate)

        #expect(try shade(of: try #require(kept(modifiedAt: replacedDate))) > 200)
        #expect(kept(modifiedAt: modificationDate) == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).count == 1)
    }

    @Test("a picture keeps its thumbnails at the two sizes kept last while its contents stay")
    func otherSizes() throws {
        let sizes = [
            CGSize(width: 240.0, height: 180.0),
            CGSize(width: 288.0, height: 216.0),
            CGSize(width: 342.0, height: 256.0)
        ]

        for size in sizes {
            try keep(
                gray: 0.2,
                modifiedAt: modificationDate,
                filling: size
            )
        }

        #expect(sizes.map({ kept(modifiedAt: modificationDate, filling: $0) != nil }) == [false, true, true])
    }

    @Test("the largest thumbnail kept for a picture is read for a box not known yet, filling the larger kept size")
    func largestThumbnail() throws {
        let smallBox = CGSize(width: 240.0, height: 180.0)
        let largeBox = CGSize(width: 342.0, height: 256.0)
        try keep(
            gray: 0.2,
            modifiedAt: modificationDate,
            filling: largeBox
        )
        try keep(
            gray: 0.2,
            modifiedAt: modificationDate,
            filling: smallBox
        )

        let largest = try #require(makeCache().largestThumbnail(of: picture(modifiedAt: modificationDate)))
        let keptSize = RecipeThumbnailCache.keptSize(holding: largeBox)

        #expect(Double(largest.width) >= keptSize.width)
        #expect(Double(largest.height) >= keptSize.height)
    }

    @Test("a picture never kept, replaced since, or telling no date has no largest thumbnail")
    func noLargestThumbnail() throws {
        #expect(makeCache().largestThumbnail(of: picture(modifiedAt: modificationDate)) == nil)

        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(makeCache().largestThumbnail(of: picture(modifiedAt: modificationDate.addingTimeInterval(60.0))) == nil)
        #expect(makeCache().largestThumbnail(of: picture(modifiedAt: nil)) == nil)
    }

    @Test("a box is kept at the smallest of a few sizes holding it, so a box resized a little keeps the same size")
    func keptSize() {
        let keptSizes = [
            CGSize(width: 362.0, height: 272.0),
            CGSize(width: 363.0, height: 273.0),
            CGSize(width: 400.0, height: 300.0),
            CGSize(width: 431.0, height: 304.0)
        ].map(RecipeThumbnailCache.keptSize(holding:))

        #expect(keptSizes == [
            CGSize(width: 362.0, height: 304.0),
            CGSize(width: 431.0, height: 304.0),
            CGSize(width: 431.0, height: 304.0),
            CGSize(width: 431.0, height: 304.0)
        ])
    }

    @Test("removing the thumbnails of the pictures not named keeps only those of the named pictures as they are now")
    func removedThumbnails() async throws {
        let otherDirectory = try TemporaryDirectory(named: "RecipeThumbnailCacheTests")
        let otherCache = RecipeThumbnailCache(
            recipeDirectory: otherDirectory.recipeDirectory,
            folderURL: directory.thumbnailCacheURL
        )
        let brioche = RecipePicture(
            id: "images/brioche.jpg",
            modificationDate: modificationDate,
            availability: .downloaded
        )
        let thumbnail = try TemporaryDirectory.picture(
            width: 480,
            height: 360,
            gray: 0.2
        )
        try keep(gray: 0.2, modifiedAt: modificationDate)
        makeCache().save(
            thumbnail,
            of: brioche,
            filling: pixelSize
        )
        otherCache.save(
            thumbnail,
            of: picture(modifiedAt: modificationDate),
            filling: pixelSize
        )

        await makeCache().removeThumbnails(keeping: [picture(modifiedAt: modificationDate)])

        #expect(kept(modifiedAt: modificationDate) != nil)
        #expect(makeCache().thumbnail(of: brioche, filling: pixelSize) == nil)
        #expect(otherCache.thumbnail(of: picture(modifiedAt: modificationDate), filling: pixelSize) == nil)

        await makeCache().removeThumbnails(keeping: [picture(modifiedAt: modificationDate.addingTimeInterval(60.0))])

        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.thumbnailCacheURL.path()).isEmpty)
    }

    @Test("a cache the system cleared finds nothing, and keeps thumbnails again")
    func clearedCache() throws {
        try keep(gray: 0.2, modifiedAt: modificationDate)
        try FileManager.default.removeItem(at: directory.thumbnailCacheURL)

        #expect(kept(modifiedAt: modificationDate) == nil)

        try keep(gray: 0.2, modifiedAt: modificationDate)

        #expect(kept(modifiedAt: modificationDate) != nil)
    }

    @Test("clearing removes every thumbnail, and leaves a cache made before keeping nothing")
    func clearing() throws {
        let cache = makeCache()
        try keep(gray: 0.2, modifiedAt: modificationDate)

        RecipeThumbnailCache.clear(folderURL: directory.thumbnailCacheURL)
        cache.save(
            try TemporaryDirectory.picture(
                width: 480,
                height: 360,
                gray: 0.2
            ),
            of: picture(modifiedAt: modificationDate),
            filling: pixelSize
        )

        #expect(!FileManager.default.fileExists(atPath: directory.thumbnailCacheURL.path()))
    }

    @Test("a cache made after clearing keeps thumbnails again")
    func keepingAfterClearing() throws {
        try keep(gray: 0.2, modifiedAt: modificationDate)
        RecipeThumbnailCache.clear(folderURL: directory.thumbnailCacheURL)

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
