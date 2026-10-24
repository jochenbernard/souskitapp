import CoreGraphics
import Foundation
@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature header", .timeLimit(.minutes(1)))
struct RecipeFeatureHeaderTests {
    private let box = CGSize(width: 1_206.0, height: 1_410.0)
    private let parser = SousParser()

    private let brioche = RecipeEntry(
        id: "brioche",
        name: "brioche",
        availability: .downloaded,
        picture: RecipePicture(
            id: "images/brioche.jpg",
            modificationDate: nil,
            availability: .downloaded
        )
    )

    private let briocheInICloud = RecipeEntry(
        id: "brioche",
        name: "brioche",
        availability: .notDownloaded
    )

    private func picture(width: Int, height: Int) throws -> CGImage {
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
        viewModel: RecipeFeatureViewModel,
        recipeRepository: PictureRepositorySpy
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: RecipeFeatureHandlerSpy(),
            parser: parser,
            preferredScaleStore: PreferredScaleStoreStub(),
            recipeRepository: recipeRepository,
            restoration: nil,
            resumesCooking: false,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("a recipe naming no picture shows its placeholder from the start, and nothing is read")
    func noPicture() async throws {
        let recipeRepository = PictureRepositorySpy(thumbnail: try picture(width: 10, height: 10))
        let viewModel = RecipeFeatureViewModel(
            recipeEntry: RecipeEntry(
                id: "crepes",
                name: "crepes",
                availability: .downloaded
            )
        )

        #expect(isPlaceholder(viewModel.headerPicture))

        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).headerDidAppear(filling: box)

        #expect(isPlaceholder(viewModel.headerPicture))
        #expect(recipeRepository.thumbnailBoxes.isEmpty)
    }

    @MainActor
    @Test("a recipe's picture is read at the header's size and shown")
    func readPicture() async throws {
        let image = try picture(width: 1_206, height: 1_410)
        let recipeRepository = PictureRepositorySpy(thumbnail: image)
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)

        #expect(isReading(viewModel.headerPicture))

        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).headerDidAppear(filling: box)

        #expect(shownPicture(viewModel.headerPicture) === image)
        #expect(recipeRepository.thumbnailBoxes == [box])
    }

    @MainActor
    @Test("a recipe opened from its card shows the card's picture from the start, and the header's own once read")
    func cardPictureFirst() async throws {
        let card = try picture(width: 537, height: 336)
        let image = try picture(width: 1_206, height: 1_410)
        let recipeRepository = PictureRepositorySpy(thumbnail: image)
        let viewModel = RecipeFeatureViewModel(
            recipeEntry: brioche,
            folderPath: ["Recipes"],
            thumbnail: card
        )

        #expect(shownPicture(viewModel.headerPicture) === card)

        await makePresenter(viewModel: viewModel, recipeRepository: recipeRepository).headerDidAppear(filling: box)

        #expect(shownPicture(viewModel.headerPicture) === image)
        #expect(recipeRepository.thumbnailBoxes == [box])
    }

    @MainActor
    @Test("the card's picture gives way to the placeholder where the header cannot read its own")
    func cardPictureUnreadable() async throws {
        let viewModel = RecipeFeatureViewModel(
            recipeEntry: brioche,
            folderPath: ["Recipes"],
            thumbnail: try picture(width: 537, height: 336)
        )
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: PictureRepositorySpy(thumbnail: nil))

        await presenter.headerDidAppear(filling: box)

        #expect(isPlaceholder(viewModel.headerPicture))
    }

    @MainActor
    @Test("a picture that cannot be read shows the placeholder")
    func unreadablePicture() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: PictureRepositorySpy(thumbnail: nil))

        await presenter.headerDidAppear(filling: box)

        #expect(isPlaceholder(viewModel.headerPicture))
    }

    @MainActor
    @Test("a header shrinking keeps the picture read, and one growing reads it again")
    func headerChangingSize() async throws {
        let recipeRepository = PictureRepositorySpy(thumbnail: try picture(width: 1_206, height: 1_410))
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        let smaller = CGSize(width: 720.0, height: 540.0)
        let larger = CGSize(width: 2_048.0, height: 1_536.0)

        await presenter.headerDidAppear(filling: box)
        await presenter.headerDidAppear(filling: smaller)
        await presenter.headerDidAppear(filling: larger)

        #expect(recipeRepository.thumbnailBoxes == [box, larger])
    }

    @MainActor
    @Test("a larger read failing leaves the picture shown")
    func largerReadFailing() async throws {
        let image = try picture(width: 1_206, height: 1_410)
        let recipeRepository = PictureRepositorySpy(thumbnail: image)
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)

        await presenter.headerDidAppear(filling: box)
        recipeRepository.thumbnail = nil
        await presenter.headerDidAppear(filling: CGSize(width: 2_048.0, height: 1_536.0))

        #expect(shownPicture(viewModel.headerPicture) === image)
    }

    @MainActor
    @Test("a picture listed once the recipe is fetched is read and shown in place of the placeholder")
    func pictureListedLater() async throws {
        let image = try picture(width: 1_206, height: 1_410)
        let viewModel = RecipeFeatureViewModel(recipeEntry: briocheInICloud)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: PictureRepositorySpy(thumbnail: image))

        await presenter.headerDidAppear(filling: box)
        presenter.entryDidChange(brioche)
        await presenter.headerDidAppear(filling: box)

        #expect(shownPicture(viewModel.headerPicture) === image)
    }

    @MainActor
    @Test("a picture replaced is read again, and the one before stays shown until it is")
    func pictureReplaced() async throws {
        let before = try picture(width: 1_206, height: 1_410)
        let recipeRepository = PictureRepositorySpy(thumbnail: before)
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        let replaced = RecipeEntry(
            id: "brioche",
            name: "brioche",
            availability: .downloaded,
            picture: RecipePicture(
                id: "images/brioche.jpg",
                modificationDate: Date(timeIntervalSince1970: 1_000.0),
                availability: .downloaded
            )
        )

        await presenter.headerDidAppear(filling: box)
        presenter.entryDidChange(replaced)

        #expect(shownPicture(viewModel.headerPicture) === before)

        let after = try picture(width: 1_206, height: 1_410)
        recipeRepository.thumbnail = after
        await presenter.headerDidAppear(filling: box)

        #expect(shownPicture(viewModel.headerPicture) === after)
        #expect(recipeRepository.thumbnailBoxes == [box, box])
    }

    @MainActor
    @Test("a picture no longer listed gives way to the placeholder")
    func pictureRemoved() async throws {
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeRepository: PictureRepositorySpy(thumbnail: try picture(width: 10, height: 10))
        )

        await presenter.headerDidAppear(filling: box)
        presenter.entryDidChange(briocheInICloud)
        await presenter.headerDidAppear(filling: box)

        #expect(isPlaceholder(viewModel.headerPicture))
    }

    @MainActor
    @Test("another picture that cannot be read gives way to the placeholder")
    func otherPictureUnreadable() async throws {
        let recipeRepository = PictureRepositorySpy(thumbnail: try picture(width: 1_206, height: 1_410))
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)
        let renamed = RecipeEntry(
            id: "brioche",
            name: "brioche",
            availability: .downloaded,
            picture: RecipePicture(
                id: "images/brioche-tressee.jpg",
                modificationDate: nil,
                availability: .downloaded
            )
        )

        await presenter.headerDidAppear(filling: box)
        presenter.entryDidChange(renamed)
        recipeRepository.thumbnail = nil
        await presenter.headerDidAppear(filling: box)

        #expect(isPlaceholder(viewModel.headerPicture))
    }

    @MainActor
    @Test("the same picture listed again is not read again")
    func samePictureListedAgain() async throws {
        let recipeRepository = PictureRepositorySpy(thumbnail: try picture(width: 1_206, height: 1_410))
        let viewModel = RecipeFeatureViewModel(recipeEntry: brioche)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: recipeRepository)

        await presenter.headerDidAppear(filling: box)
        presenter.entryDidChange(brioche)
        await presenter.headerDidAppear(filling: box)

        #expect(recipeRepository.thumbnailBoxes == [box])
    }

    private func isPlaceholder(_ headerPicture: HeaderPicture) -> Bool {
        switch headerPicture {
        case .placeholder:
            true

        case .reading, .read:
            false
        }
    }

    private func isReading(_ headerPicture: HeaderPicture) -> Bool {
        switch headerPicture {
        case .reading:
            true

        case .read, .placeholder:
            false
        }
    }

    private func shownPicture(_ headerPicture: HeaderPicture) -> CGImage? {
        switch headerPicture {
        case .read(let image):
            image

        case .reading, .placeholder:
            nil
        }
    }
}
