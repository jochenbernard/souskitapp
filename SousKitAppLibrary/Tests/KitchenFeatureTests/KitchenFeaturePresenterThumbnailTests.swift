import CoreGraphics
import Foundation
@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature presenter thumbnails")
struct KitchenFeaturePresenterThumbnailTests {
    private let box = CGSize(width: 480.0, height: 360.0)
    private let parser = SousParser()

    private func picture(
        _ name: String = "gratin-dauphinois",
        modifiedAt date: Date? = nil,
        availability: RecipeAvailability = .downloaded
    ) -> RecipePicture {
        RecipePicture(
            id: "images/\(name).jpg",
            modificationDate: date,
            availability: availability
        )
    }

    private func thumbnail(width: Int, height: Int) throws -> CGImage {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )

        return try #require(context.makeImage())
    }

    @MainActor
    private func makePresenter(recipeRepository: RecipeRepositorySpy) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes"),
            parser: parser,
            recipeRepository: recipeRepository
        )
    }

    @MainActor
    @Test("a card's picture is read from the repository at the card's size, and shown at once the next time")
    func readPicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let image = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": image]
        let presenter = makePresenter(recipeRepository: recipeRepository)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

        #expect(presenter.lastThumbnail(of: picture(modifiedAt: date)) == nil)
        #expect(await presenter.thumbnail(of: picture(modifiedAt: date), filling: box) === image)
        #expect(presenter.lastThumbnail(of: picture(modifiedAt: date)) === image)
        #expect(recipeRepository.thumbnailReads == [picture(modifiedAt: date)])
    }

    @MainActor
    @Test("a picture read for a card serves a box it covers without reading it again, and a larger box reads it")
    func coveredBox() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let image = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": image]
        let presenter = makePresenter(recipeRepository: recipeRepository)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        _ = await presenter.thumbnail(of: picture(modifiedAt: date), filling: box)

        let fanThumbnail = await presenter.thumbnail(
            of: picture(modifiedAt: date),
            filling: CGSize(width: 240.0, height: 223.0)
        )

        #expect(fanThumbnail === image)
        #expect(recipeRepository.thumbnailReads.count == 1)

        _ = await presenter.thumbnail(of: picture(modifiedAt: date), filling: CGSize(width: 640.0, height: 480.0))

        #expect(recipeRepository.thumbnailReads.count == 2)
    }

    @MainActor
    @Test("a picture replaced since it was read is not shown as it was")
    func replacedPicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = makePresenter(recipeRepository: recipeRepository)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

        _ = await presenter.thumbnail(of: picture(modifiedAt: date), filling: box)

        #expect(presenter.lastThumbnail(of: picture(modifiedAt: date.addingTimeInterval(60.0))) == nil)
    }

    @MainActor
    @Test("a picture that cannot be read shows none")
    func unreadablePicture() async {
        let presenter = makePresenter(recipeRepository: RecipeRepositorySpy())

        #expect(await presenter.thumbnail(of: picture(modifiedAt: nil), filling: box) == nil)
        #expect(presenter.lastThumbnail(of: picture(modifiedAt: nil)) == nil)
    }

    @MainActor
    @Test("the thumbnails read longest ago are let go once they hold more than the budget")
    func memoryBudget() throws {
        let image = try thumbnail(width: 100, height: 100)
        let memory = RecipeThumbnailMemory(byteBudget: image.bytesPerRow * image.height * 2)
        let pictures = ["brioche", "crepes", "madeleines"].map({ picture($0) })

        pictures.forEach({ memory.keep(image, of: $0) })

        #expect(pictures.map({ memory.thumbnail(of: $0) != nil }) == [false, true, true])
    }

    @MainActor
    @Test("a picture landing from iCloud shows what was read of it before")
    func landedPicture() throws {
        let image = try thumbnail(width: 100, height: 100)
        let memory = RecipeThumbnailMemory()
        memory.keep(image, of: picture("crepes"))

        #expect(memory.thumbnail(of: picture("crepes", availability: .notDownloaded)) === image)
    }
}
