import Foundation
@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature sharing", .timeLimit(.minutes(1)))
struct RecipeFeatureSharingTests {
    private let parser = SousParser()

    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .downloaded
    )

    private let crepesText = "Whisk @{200 g} flour@ into a batter with @{4} eggs@."

    @MainActor
    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        recipeRepository: RecipeRepository
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
    @Test("a read recipe opens the share sheet on a copy of its file, and closing the sheet lets it go")
    func sharesTheFile() async throws {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: RecipeRepositoryStub(text: crepesText))

        await presenter.viewDidAppear()
        await presenter.didTapShare()

        let url = try #require(viewModel.sharedFileURL)
        #expect(try Data(contentsOf: url) == Data(crepesText.utf8))

        presenter.didDismissSharing()

        #expect(viewModel.sharedFileURL == nil)
    }

    @MainActor
    @Test("a recipe not yet read opens no share sheet")
    func unreadRecipe() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: RecipeRepositoryStub(text: crepesText))

        await presenter.didTapShare()

        #expect(viewModel.sharedFileURL == nil)
    }

    @MainActor
    @Test("a file that cannot be copied opens no share sheet")
    func failedExport() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeRepository: RecipeRepositoryStub(text: crepesText, failsExport: true)
        )

        await presenter.viewDidAppear()
        await presenter.didTapShare()

        #expect(viewModel.sharedFileURL == nil)
    }

    @MainActor
    @Test("a copy arriving after the screen was left opens no share sheet")
    func cancelledShare() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeRepository: RecipeRepositoryStub(text: crepesText))

        await presenter.viewDidAppear()
        let sharing = Task {
            await presenter.didTapShare()
        }
        sharing.cancel()
        await sharing.value

        #expect(viewModel.sharedFileURL == nil)
    }
}
