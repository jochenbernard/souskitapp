import CoreGraphics
import Foundation
@testable import KitchenFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature presenter cached thumbnails", .timeLimit(.minutes(1)))
struct KitchenCachedThumbnailTests {
    private let box = CGSize(width: 480.0, height: 360.0)
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
    private let parser = SousParser()

    private func picture(_ name: String) -> RecipePicture {
        RecipePicture(
            id: "images/\(name).jpg",
            modificationDate: date,
            availability: .downloaded
        )
    }

    /// A recipe listed with the picture of its own name.
    private func entry(_ name: String, in folderPath: [String] = []) -> RecipeEntry {
        RecipeEntry(
            id: (folderPath + [name]).joined(separator: "/"),
            name: name,
            availability: .downloaded,
            folderPath: folderPath,
            picture: picture(name)
        )
    }

    private func thumbnail() throws -> CGImage {
        try #require(
            CGContext(
                data: nil,
                width: 480,
                height: 360,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )?.makeImage()
        )
    }

    /// The view model once the repository lists each of the listings in turn and ends.
    @MainActor
    private func viewModel(
        listing listings: [[RecipeEntry]],
        from recipeRepository: RecipeRepositorySpy
    ) async -> KitchenFeatureViewModel {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )

        for listing in listings {
            recipeRepository.send(.success(listing))
        }

        recipeRepository.finish()
        await presenter.stackDidAppear()

        return viewModel
    }

    @MainActor
    @Test("the thumbnails kept for the first cards show with them, the folders' stacked pictures included, unread")
    func firstCards() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let image = try thumbnail()
        recipeRepository.cachedThumbnails = ["images/brioche.jpg": image, "images/crepes.jpg": image]

        let viewModel = await viewModel(
            listing: [[entry("brioche", in: ["Baking"]), entry("crepes"), entry("vinaigrette")]],
            from: recipeRepository
        )

        #expect(viewModel.thumbnails[picture("brioche")] === image)
        #expect(viewModel.thumbnails[picture("crepes")] === image)
        #expect(viewModel.thumbnails[picture("vinaigrette")] == nil)
        #expect(recipeRepository.thumbnailReads.isEmpty)
    }

    @MainActor
    @Test("a card showing a kept thumbnail as large as its box does not read its picture")
    func keptThumbnailServesTheCard() async throws {
        let recipeRepository = RecipeRepositorySpy()
        recipeRepository.cachedThumbnails = ["images/crepes.jpg": try thumbnail()]
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes"),
            parser: parser,
            recipeRepository: recipeRepository
        )
        recipeRepository.send(.success([entry("crepes")]))
        recipeRepository.finish()
        await presenter.stackDidAppear()

        await presenter.pictureDidAppear(picture("crepes"), filling: box)

        #expect(recipeRepository.thumbnailReads.isEmpty)
    }

    @MainActor
    @Test("only the cards shown first are given kept thumbnails, so a recipe listed later reads its picture")
    func laterListing() async throws {
        let recipeRepository = RecipeRepositorySpy()
        recipeRepository.cachedThumbnails = ["images/crepes.jpg": try thumbnail()]

        let viewModel = await viewModel(
            listing: [[entry("brioche")], [entry("brioche"), entry("crepes")]],
            from: recipeRepository
        )

        #expect(viewModel.thumbnails[picture("crepes")] == nil)
    }

    @MainActor
    @Test("a picture that fails to read is noted as failed, until a thumbnail of it is read")
    func failedRead() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )

        #expect(!viewModel.thumbnails.didFail(picture("crepes")))

        await presenter.pictureDidAppear(picture("crepes"), filling: box)

        #expect(viewModel.thumbnails.didFail(picture("crepes")))

        recipeRepository.thumbnails = ["images/crepes.jpg": try thumbnail()]
        await presenter.pictureDidAppear(picture("crepes"), filling: box)

        #expect(!viewModel.thumbnails.didFail(picture("crepes")))
    }
}
