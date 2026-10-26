import CoreGraphics
import Foundation
@testable import KitchenFeature
import RecipeLibrary
import Testing

extension KitchenFeaturePresenterThumbnailTests {
    private static let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

    /// A recipe listed with the picture of its own name.
    private func entry(_ name: String, in folderPath: [String] = []) -> RecipeEntry {
        RecipeEntry(
            id: (folderPath + [name]).joined(separator: "/"),
            name: name,
            availability: .downloaded,
            folderPath: folderPath,
            picture: picture(name, modifiedAt: Self.date)
        )
    }

    /// The presenter once the repository lists each of the listings in turn and ends.
    @MainActor
    private func makePresenter(
        listing listings: [[RecipeEntry]],
        from recipeRepository: RecipeRepositorySpy
    ) async -> KitchenFeaturePresenter {
        let presenter = makePresenter(
            recipeRepository: recipeRepository,
            viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        )

        for listing in listings {
            recipeRepository.send(.success(listing))
        }

        recipeRepository.finish()
        await presenter.stackDidAppear()

        return presenter
    }

    @MainActor
    @Test("the thumbnails kept for the first cards show with them, the folders' stacked pictures included, unread")
    func firstCards() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let image = try thumbnail(width: 480, height: 360)
        recipeRepository.cachedThumbnails = ["images/brioche.jpg": image, "images/crepes.jpg": image]

        let viewModel = await makePresenter(
            listing: [[entry("brioche", in: ["Baking"]), entry("crepes"), entry("vinaigrette")]],
            from: recipeRepository
        ).viewModel

        #expect(viewModel.thumbnails[picture("brioche")] === image)
        #expect(viewModel.thumbnails[picture("crepes")] === image)
        #expect(viewModel.thumbnails[picture("vinaigrette")] == nil)
        #expect(recipeRepository.thumbnailReads.isEmpty)
    }

    @MainActor
    @Test("a screen holding more cards than the read ahead is given the kept thumbnails of every card on it")
    func screenOfCards() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let image = try thumbnail(width: 480, height: 360)
        let names = (10...49).map({ "dish-\($0)" })
        recipeRepository.cachedThumbnails = Dictionary(uniqueKeysWithValues: names.map({ ("images/\($0).jpg", image) }))
        let presenter = makePresenter(
            recipeRepository: recipeRepository,
            viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        )
        presenter.screenDidResize(holding: 30)
        recipeRepository.send(.success(names.map({ entry($0) })))
        recipeRepository.finish()

        await presenter.stackDidAppear()

        let keptNames = names.filter({ presenter.viewModel.thumbnails[picture($0)] != nil })
        #expect(keptNames == Array(names.prefix(30)))
    }

    @MainActor
    @Test("a card showing a kept thumbnail as large as its box does not read its picture")
    func keptThumbnailServesTheCard() async throws {
        let recipeRepository = RecipeRepositorySpy()
        recipeRepository.cachedThumbnails = ["images/crepes.jpg": try thumbnail(width: 480, height: 360)]
        let presenter = await makePresenter(listing: [[entry("crepes")]], from: recipeRepository)

        await presenter.pictureDidAppear(picture("crepes", modifiedAt: Self.date), filling: box)

        #expect(recipeRepository.thumbnailReads.isEmpty)
    }

    @MainActor
    @Test("only the cards shown first are given kept thumbnails, so a recipe listed later reads its picture")
    func laterListing() async throws {
        let recipeRepository = RecipeRepositorySpy()
        recipeRepository.cachedThumbnails = ["images/crepes.jpg": try thumbnail(width: 480, height: 360)]

        let viewModel = await makePresenter(
            listing: [[entry("brioche")], [entry("brioche"), entry("crepes")]],
            from: recipeRepository
        ).viewModel

        #expect(viewModel.thumbnails[picture("crepes")] == nil)
    }

    @MainActor
    @Test("a picture that fails to read is noted as failed, until a thumbnail of it is read")
    func failedRead() async throws {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = makePresenter(recipeRepository: recipeRepository, viewModel: viewModel)
        let crepes = picture("crepes", modifiedAt: Self.date)

        #expect(!viewModel.thumbnails.didFail(crepes))

        await presenter.pictureDidAppear(crepes, filling: box)

        #expect(viewModel.thumbnails.didFail(crepes))

        recipeRepository.thumbnails = ["images/crepes.jpg": try thumbnail(width: 480, height: 360)]
        await presenter.pictureDidAppear(crepes, filling: box)

        #expect(!viewModel.thumbnails.didFail(crepes))
    }
}
