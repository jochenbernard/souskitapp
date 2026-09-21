@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature scaling", .timeLimit(.minutes(1)))
struct RecipeFeatureScalingTests {
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

    private let gratinText = """
        ---
        title: Gratin Dauphinois
        servings: 6
        yield: [1.8 kg]
        ---

        Peel @{1.2 kg} potatoes@ and simmer them in @{500 ml} cream@.
        """

    private let vinaigretteText = """
        ---
        title: Vinaigrette
        ---

        Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
        """

    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        handler: RecipeFeatureHandler = RecipeFeatureHandlerSpy(),
        recipeText: String? = "Whisk."
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: handler,
            recipeRepository: RecipeRepositoryStub(text: recipeText),
            viewModel: viewModel
        )
    }

    @MainActor
    private func scaledRecipe(of viewModel: RecipeFeatureViewModel) -> ScaledRecipe? {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return nil
        }

        return recipe
    }

    @MainActor
    @Test("the sheet opens on the servings a recipe declares")
    func fieldAfterTheFirstRead() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: crepesText).viewDidAppear()

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .servings, value: 4.0))
        #expect(viewModel.scaleText == "4")
    }

    @MainActor
    @Test("a recipe declaring no servings opens on the multiplier")
    func fieldWithoutDeclaredServings() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: vinaigretteText).viewDidAppear()

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(viewModel.scaleText == "1")
    }

    @MainActor
    @Test("tapping the scale opens the sheet")
    func openingTheScaleSheet() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        makePresenter(viewModel: viewModel).didTapScale()

        #expect(viewModel.isScaling)
    }

    @MainActor
    @Test("typing a number takes the recipe to it, on the target in force")
    func typingANumber() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.scale == RecipeScale(target: .servings, value: 8.0))
        #expect(recipe.scaled.metadata.servings == 8.0)
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["8", "500 g"])
        #expect(viewModel.scaleText == "8")
    }

    @MainActor
    @Test("a number scales the recipe as written rather than what is on screen")
    func scalingFromTheRecipeAsWritten() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didChangeScaleText("12")

        #expect(scaledRecipe(of: viewModel)?.scaled.ingredients.map(\.amount?.text) == ["12", "750 g"])
    }

    @MainActor
    @Test("a field holding no number yet leaves the recipe where it is")
    func typingTowardANumber() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didChangeScaleText("")

        #expect(viewModel.scaleText.isEmpty)
        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .servings, value: 8.0))
    }

    @MainActor
    @Test("the plus takes the recipe a step up, and writes the number it lands on")
    func steppingTheNumber() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didStepScale(by: 1.0)

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .servings, value: 5.0))
        #expect(viewModel.scaleText == "5")
    }

    @MainActor
    @Test("the minus stops where a recipe stops making sense")
    func steppingBelowTheRange() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("1")
        presenter.didStepScale(by: -1.0)

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .servings, value: 1.0))
    }

    @MainActor
    @Test("choosing another target holds the amount and counts it the other way")
    func choosingAnotherTarget() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didTapTarget(.multiplier)

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.scale == RecipeScale(target: .multiplier, value: 2.0))
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["8", "500 g"])
        #expect(viewModel.scaleText == "2")
    }

    @MainActor
    @Test("a target the recipe declares nothing of is not one to scale by")
    func choosingATargetTheRecipeHasNot() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: vinaigretteText)

        await presenter.viewDidAppear()
        presenter.didTapTarget(.servings)

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .multiplier, value: 1.0))
    }

    @MainActor
    @Test("reset takes the recipe back to the target and the number it opens on")
    func resetting() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didTapTarget(.multiplier)
        presenter.didTapReset()

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.isDefault)
        #expect(recipe.scale == RecipeScale(target: .servings, value: 4.0))
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["4", "250 g"])
        #expect(viewModel.scaleText == "4")
    }

    @MainActor
    @Test("closing the sheet writes the scale in force back into the field")
    func closingTheScaleSheet() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didTapScale()
        presenter.didChangeScaleText("8")
        presenter.didChangeScaleText("")
        presenter.didChangeIsScaling(false)

        #expect(!viewModel.isScaling)
        #expect(viewModel.scaleText == "8")
    }

    @MainActor
    @Test("reading the recipe again keeps the scale it is at")
    func readingAgainKeepsTheScale() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        await presenter.viewDidAppear()

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.scale == RecipeScale(target: .servings, value: 8.0))
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["8", "500 g"])
    }

    @MainActor
    @Test("choosing a yield holds the amount and reads it in the unit the recipe declares")
    func choosingAYield() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: gratinText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("12")
        presenter.didTapTarget(.yield(unit: "kg"))

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.scale == RecipeScale(target: .yield(unit: "kg"), value: 3.6))
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["2.4 kg", "1000 ml"])
        // Read back rather than compared as text, which is written in the reader's notation.
        #expect(ScaleNumber.value(of: viewModel.scaleText) == 3.6)
    }

    @MainActor
    @Test("typing a yield takes the recipe to it")
    func typingAYield() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: gratinText)

        await presenter.viewDidAppear()
        presenter.didTapTarget(.yield(unit: "kg"))
        presenter.didChangeScaleText("0.9")

        guard let recipe = scaledRecipe(of: viewModel) else {
            return
        }

        #expect(recipe.scaled.metadata.yields.map(\.text) == ["0.9 kg"])
        #expect(recipe.scaled.metadata.servings == 3.0)
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["0.6 kg", "250 ml"])
    }

    @MainActor
    @Test("the plus steps a yield by a round share of it")
    func steppingAYield() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: gratinText)

        await presenter.viewDidAppear()
        presenter.didTapTarget(.yield(unit: "kg"))
        presenter.didStepScale(by: 1.0)

        #expect(scaledRecipe(of: viewModel)?.scale == RecipeScale(target: .yield(unit: "kg"), value: 1.9))
        #expect(ScaleNumber.value(of: viewModel.scaleText) == 1.9)
    }
}
