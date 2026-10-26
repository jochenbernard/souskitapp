import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

extension FileRecipeRepositoryTests {
    @Test("a cached thumbnail is the one a read of the picture kept, and none is made for a picture never read")
    func cachedThumbnail() async throws {
        try writeGratin(width: 1_600, height: 1_000)
        let picture = try self.picture(at: "gratin-dauphinois.png")
        let box = CGSize(width: 400.0, height: 300.0)

        #expect(await makeRepository().cachedThumbnail(of: picture) == nil)
        #expect(!FileManager.default.fileExists(atPath: directory.thumbnailCacheURL.path()))

        _ = try await makeRepository().readThumbnail(of: picture, filling: box)
        let thumbnail = try #require(await makeRepository().cachedThumbnail(of: picture))

        #expect(Double(thumbnail.width) >= box.width)
        #expect(Double(thumbnail.height) >= box.height)
    }
}
