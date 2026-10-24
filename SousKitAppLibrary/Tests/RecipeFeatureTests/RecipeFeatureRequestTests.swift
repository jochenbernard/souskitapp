@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature requests", .timeLimit(.minutes(1)))
struct RecipeFeatureRequestTests {
    private let parser = SousParser()

    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .downloaded
    )

    private let crepesText = """
        ---
        title: Crepes
        servings: 4
        ---

        Whisk @{4} eggs@ into @{250 g} flour@.
        """

    @MainActor
    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        handler: RecipeFeatureHandler,
        recipeText: String?
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: handler,
            parser: parser,
            preferredScaleStore: PreferredScaleStoreStub(),
            recipeRepository: RecipeRepositoryStub(text: recipeText),
            restoration: nil,
            resumesCooking: false,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("cooking asked for before the recipe is read starts once it is read, as the button starts it")
    func cookingWaitsForTheRead() async {
        let handler = RecipeFeatureHandlerSpy()
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            recipeText: crepesText
        )

        presenter.didRequestCooking()

        #expect(handler.cookedRecipes.isEmpty)

        await presenter.viewDidAppear()

        #expect(handler.cookedRecipes.map(\.metadata.title) == ["Crepes"])
        #expect(handler.resumedRecipes.isEmpty)

        await presenter.viewDidAppear()

        #expect(handler.cookedRecipes.count == 1)
    }

    @MainActor
    @Test("cooking asked for once the recipe is read starts at once")
    func cookingStartsOnceRead() async {
        let handler = RecipeFeatureHandlerSpy()
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            recipeText: crepesText
        )

        await presenter.viewDidAppear()
        presenter.didRequestCooking()

        #expect(handler.cookedRecipes.count == 1)
    }

    @MainActor
    @Test("cooking asked for a recipe of no steps, or one that cannot be read, starts nothing")
    func cookingNeedsSteps() async {
        let handler = RecipeFeatureHandlerSpy()

        for recipeText in ["---\ntitle: Crepes\n---", nil] {
            let presenter = makePresenter(
                viewModel: RecipeFeatureViewModel(recipeEntry: crepes),
                handler: handler,
                recipeText: recipeText
            )

            presenter.didRequestCooking()
            await presenter.viewDidAppear()
        }

        #expect(handler.cookedRecipes.isEmpty)
    }

    @MainActor
    @Test("the scale sheet asked for opens once the recipe is read, and not where it cannot be read")
    func scalingWaitsForTheRead() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: RecipeFeatureHandlerSpy(),
            recipeText: crepesText
        )

        presenter.didRequestScaling()

        #expect(!viewModel.isScaling)

        await presenter.viewDidAppear()

        #expect(viewModel.isScaling)

        let unreadable = RecipeFeatureViewModel(recipeEntry: crepes)
        let unreadablePresenter = makePresenter(
            viewModel: unreadable,
            handler: RecipeFeatureHandlerSpy(),
            recipeText: nil
        )

        unreadablePresenter.didRequestScaling()
        await unreadablePresenter.viewDidAppear()

        #expect(!unreadable.isScaling)
    }

    @MainActor
    @Test("the title is the listed one until the recipe is read, then the one its header gives")
    func titleFollowsTheRead() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        #expect(viewModel.title == "crepes")

        await makePresenter(
            viewModel: viewModel,
            handler: RecipeFeatureHandlerSpy(),
            recipeText: crepesText
        )
        .viewDidAppear()

        #expect(viewModel.title == "Crepes")
    }
}
