import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import Testing

@Suite("Recipe thumbnail maker")
final class RecipeThumbnailMakerTests {
    private let box = CGSize(width: 400.0, height: 300.0)
    private let directory: TemporaryDirectory

    init() throws {
        self.directory = try TemporaryDirectory(named: "RecipeThumbnailMakerTests")
    }

    /// A thumbnail filling the box, of a picture of the given size.
    private func thumbnail(ofPictureWidth width: Int, height: Int) throws -> CGImage {
        try directory.writePicture(
            named: "gratin-dauphinois.png",
            width: width,
            height: height
        )

        return try RecipeThumbnailMaker.thumbnail(
            ofImageAt: directory.url.appending(path: "gratin-dauphinois.png"),
            filling: box
        )
    }

    @Test("a wide picture fills the box's height and reaches past its sides")
    func widePicture() throws {
        let thumbnail = try thumbnail(ofPictureWidth: 1_600, height: 1_000)

        #expect(thumbnail.height == 300)
        #expect(thumbnail.width == 480)
    }

    @Test("a tall picture fills the box's width and reaches past its top and bottom")
    func tallPicture() throws {
        let thumbnail = try thumbnail(ofPictureWidth: 1_000, height: 1_600)

        #expect(thumbnail.width == 400)
        #expect(thumbnail.height == 640)
    }

    @Test("a picture smaller than the box is never scaled up")
    func smallPicture() throws {
        let thumbnail = try thumbnail(ofPictureWidth: 120, height: 90)

        #expect(thumbnail.width == 120)
        #expect(thumbnail.height == 90)
    }

    @Test("a file holding no picture fails")
    func notAPicture() throws {
        try directory.writeFile(named: "croque-monsieur.jpg", "---\ntitle: Croque Monsieur\n---")

        #expect(throws: CocoaError.self) {
            try RecipeThumbnailMaker.thumbnail(
                ofImageAt: directory.url.appending(path: "croque-monsieur.jpg"),
                filling: box
            )
        }
    }
}
