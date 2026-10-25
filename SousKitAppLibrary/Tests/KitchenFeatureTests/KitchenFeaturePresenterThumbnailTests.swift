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
    private func makePresenter(
        recipeRepository: RecipeRepositorySpy,
        viewModel: KitchenFeatureViewModel
    ) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )
    }

    @MainActor
    @Test("a card's picture is read from the repository at the card's size, and shown at once the next time")
    func readPicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let image = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": image]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

        #expect(viewModel.thumbnails[picture(modifiedAt: date)] == nil)

        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: box)
        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: box)

        #expect(viewModel.thumbnails[picture(modifiedAt: date)] === image)
        #expect(recipeRepository.thumbnailReads == [picture(modifiedAt: date)])
    }

    @MainActor
    @Test("a picture read for a card serves a box it covers without reading it again, and a larger box reads it")
    func coveredBox() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let image = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": image]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: box)

        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: CGSize(width: 240.0, height: 223.0))

        #expect(viewModel.thumbnails[picture(modifiedAt: date)] === image)
        #expect(recipeRepository.thumbnailReads.count == 1)

        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: CGSize(width: 640.0, height: 480.0))

        #expect(recipeRepository.thumbnailReads.count == 2)
    }

    @MainActor
    @Test("a picture replaced since it was read shows as it was until it is read again, then as it is")
    func replacedPicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let replacement = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        let replacedPicture = picture(modifiedAt: date.addingTimeInterval(60.0))
        await presenter.pictureDidAppear(picture(modifiedAt: date), filling: box)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": replacement]

        #expect(viewModel.thumbnails[replacedPicture] != nil)

        await presenter.pictureDidAppear(replacedPicture, filling: box)

        #expect(viewModel.thumbnails[replacedPicture] === replacement)
        #expect(recipeRepository.thumbnailReads.count == 2)
    }

    @MainActor
    @Test("a picture telling no date is read again each time a card shows it, and shows what was read last")
    func undatedPicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let replacement = try thumbnail(width: 480, height: 360)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        await presenter.pictureDidAppear(picture(modifiedAt: nil), filling: box)
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": replacement]

        await presenter.pictureDidAppear(picture(modifiedAt: nil), filling: box)

        #expect(viewModel.thumbnails[picture(modifiedAt: nil)] === replacement)
        #expect(recipeRepository.thumbnailReads.count == 2)
    }

    @MainActor
    @Test("a picture that cannot be read shows none, not what was read of it before")
    func unreadablePicture() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        await presenter.pictureDidAppear(picture(modifiedAt: nil), filling: box)
        recipeRepository.thumbnails = [:]

        await presenter.pictureDidAppear(picture(modifiedAt: nil), filling: box)

        #expect(viewModel.thumbnails[picture(modifiedAt: nil)] == nil)
    }

    @MainActor
    @Test("a card that leaves before its picture is read shows nothing of it")
    func cancelledRead() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        recipeRepository.thumbnails = ["images/gratin-dauphinois.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        let task = Task {
            await presenter.pictureDidAppear(picture(modifiedAt: date), filling: box)
        }

        task.cancel()
        await task.value

        #expect(viewModel.thumbnails[picture(modifiedAt: date)] == nil)
    }

    @MainActor
    @Test("the thumbnails read longest ago are let go once they hold more than the budget, and no longer shown")
    func memoryBudget() throws {
        let image = try thumbnail(width: 100, height: 100)
        let thumbnails = KitchenThumbnails()
        let memory = RecipeThumbnailMemory(
            shownThumbnails: thumbnails,
            byteBudget: image.bytesPerRow * image.height * 2
        )
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        let pictures = ["brioche", "crepes", "madeleines"].map({ picture($0, modifiedAt: date) })

        pictures.forEach({ memory.keep(image, of: $0) })

        #expect(pictures.map({ thumbnails[$0] != nil }) == [false, true, true])
        #expect(!memory.holdsThumbnail(of: pictures[0], filling: CGSize(width: 100.0, height: 100.0)))
    }

    @MainActor
    @Test("a picture landing from iCloud shows what was read of it before")
    func landedPicture() throws {
        let image = try thumbnail(width: 100, height: 100)
        let thumbnails = KitchenThumbnails()
        let memory = RecipeThumbnailMemory(shownThumbnails: thumbnails)
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)
        let landedPicture = picture("crepes", modifiedAt: date)
        memory.keep(image, of: picture("crepes", modifiedAt: date, availability: .notDownloaded))

        #expect(memory.holdsThumbnail(of: landedPicture, filling: CGSize(width: 100.0, height: 100.0)))
        #expect(thumbnails[landedPicture] === image)
    }
}
