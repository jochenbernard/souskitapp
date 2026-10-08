@testable import RecipeFeature
import RecipeLibrary
import RecipeScaling
import SousKit
import Testing

@Suite("Recipe feature preferred scale", .timeLimit(.minutes(1)))
struct RecipeFeaturePreferredScaleTests {
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

    private let vinaigretteText = """
        ---
        title: Vinaigrette
        ---

        Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
        """

    @MainActor
    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        recipeText: String,
        preferredScale: PreferredScale
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: RecipeFeatureHandlerSpy(),
            parser: parser,
            preferredScaleStore: PreferredScaleStoreStub(preferredScale),
            recipeRepository: RecipeRepositoryStub(text: recipeText),
            restoration: nil,
            resumesCooking: false,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("a recipe declaring servings opens on the servings preferred")
    func preferredServings() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(
            viewModel: viewModel,
            recipeText: crepesText,
            preferredScale: .servings(2.0)
        )
        .viewDidAppear()

        #expect(viewModel.scaledRecipe?.scale == RecipeScale(target: .servings, value: 2.0))
        #expect(viewModel.scaledRecipe?.isDefault == true)
        #expect(viewModel.scaledRecipe?.scaled.ingredients.map(\.amount?.text) == ["2", "125 g"])
        #expect(viewModel.scaleText == "2")
    }

    @MainActor
    @Test("a recipe declaring no servings opens as written where servings are preferred")
    func preferredServingsWithoutDeclaredServings() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(
            viewModel: viewModel,
            recipeText: vinaigretteText,
            preferredScale: .servings(2.0)
        )
        .viewDidAppear()

        #expect(viewModel.scaledRecipe?.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(viewModel.scaledRecipe?.scaled == viewModel.scaledRecipe?.asWritten)
    }

    @MainActor
    @Test("every recipe opens on the multiple preferred, counted the way it counts itself")
    func preferredMultiplier() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(
            viewModel: viewModel,
            recipeText: crepesText,
            preferredScale: .multiplier(2.0)
        )
        .viewDidAppear()

        #expect(viewModel.scaledRecipe?.scale == RecipeScale(target: .servings, value: 8.0))
        #expect(viewModel.scaledRecipe?.scaled.ingredients.map(\.amount?.text) == ["8", "500 g"])
        #expect(viewModel.scaleText == "8")
    }

    @MainActor
    @Test("reset takes the recipe back to the servings preferred")
    func resettingToThePreferredScale() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeText: crepesText,
            preferredScale: .servings(2.0)
        )

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didTapReset()

        #expect(viewModel.scaledRecipe?.scale == RecipeScale(target: .servings, value: 2.0))
        #expect(viewModel.scaledRecipe?.isDefault == true)
        #expect(viewModel.scaleText == "2")
    }
}
