@testable import RecipeFeature
import RecipeLibrary
import RecipeScaling
import SousKit
import Testing

@Suite("Recipe feature presenter", .timeLimit(.minutes(1)))
struct RecipeFeaturePresenterTests {
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
        handler: RecipeFeatureHandler = RecipeFeatureHandlerSpy(),
        recipeText: String? = "Whisk."
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
    @Test("the view model starts out reading")
    func readingBeforeTheFirstRead() {
        guard case .reading = RecipeFeatureViewModel(recipeEntry: crepes).recipeContent else {
            Issue.record("The recipe content did not start out reading.")
            return
        }
    }

    @MainActor
    @Test("a parsed recipe reaches the view model")
    func recipeReachesTheViewModel() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeText: """
                ---
                title: Crepes
                servings: 4
                ---

                Whisk @{4} eggs@ for ~1 min~ in a #mixing bowl#.
                """
        )

        await presenter.viewDidAppear()

        guard let recipe = viewModel.scaledRecipe else {
            return
        }

        #expect(recipe.scaled.metadata.title == "Crepes")
        #expect(recipe.scaled.metadata.servings == 4.0)
        #expect(recipe.scaled.ingredients.map(\.name) == ["eggs"])
        #expect(recipe.scaled.cookware.map(\.name) == ["mixing bowl"])
        #expect(recipe.scaled.steps.count == 1)
    }

    @MainActor
    @Test("an empty recipe reaches the view model holding nothing")
    func emptyRecipeReachesTheViewModel() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: "").viewDidAppear()

        #expect(viewModel.scaledRecipe?.scaled.steps.isEmpty == true)
    }

    @MainActor
    @Test("reading the recipe again keeps the scale it is at")
    func readingAgainKeepsTheScale() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(viewModel: viewModel, recipeText: crepesText)

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        await presenter.viewDidAppear()

        guard let recipe = viewModel.scaledRecipe else {
            return
        }

        #expect(recipe.scale == RecipeScale(target: .servings, value: 8.0))
        #expect(recipe.scaled.ingredients.map(\.amount?.text) == ["8", "500 g"])
    }

    @MainActor
    @Test("a recipe no cook has scaled opens on what its file declares when read again")
    func readingAChangedFileAgain() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: crepesText).viewDidAppear()
        await makePresenter(
            viewModel: viewModel,
            recipeText: """
                ---
                title: Crepes
                servings: 6
                ---

                Whisk @{6} eggs@ into @{375 g} flour@.
                """
        ).viewDidAppear()

        guard let recipe = viewModel.scaledRecipe else {
            return
        }

        #expect(recipe.isDefault)
        #expect(recipe.scale == RecipeScale(target: .servings, value: 6.0))
        #expect(viewModel.scaleText == "6")
    }

    @MainActor
    @Test("the ingredients open, and the cookware stays closed")
    func sectionsOpenByDefault() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        #expect(viewModel.expandedSections == [.ingredients])
    }

    @MainActor
    @Test("expanding a closed section opens it")
    func openingASection() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        makePresenter(viewModel: viewModel).didChangeIsExpanded(true, of: .cookware)

        #expect(viewModel.expandedSections == [.ingredients, .cookware])
    }

    @MainActor
    @Test("collapsing an open section closes it")
    func closingASection() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        makePresenter(viewModel: viewModel).didChangeIsExpanded(false, of: .ingredients)

        #expect(viewModel.expandedSections.isEmpty)
    }

    @MainActor
    @Test("expanding an open section leaves it open")
    func openingAnOpenSection() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        makePresenter(viewModel: viewModel).didChangeIsExpanded(true, of: .ingredients)

        #expect(viewModel.expandedSections == RecipeSection.openByDefault)
    }

    @MainActor
    @Test("tapping cook reports the recipe at the scale it is on screen at")
    func cookingReportsTheScaledRecipe() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            recipeText: crepesText
        )

        await presenter.viewDidAppear()
        presenter.didChangeScaleText("8")
        presenter.didTapCook()

        #expect(handler.cookedRecipes.map(\.metadata.servings) == [8.0])
        #expect(handler.cookedRecipes.flatMap({ $0.ingredients.map(\.amount?.text) }) == ["8", "500 g"])
    }

    @MainActor
    @Test("tapping cook before the recipe is read reports nothing")
    func cookingBeforeTheRecipeIsRead() {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let handler = RecipeFeatureHandlerSpy()

        makePresenter(viewModel: viewModel, handler: handler).didTapCook()

        #expect(handler.cookedRecipes.isEmpty)
    }

    @MainActor
    @Test("a recipe that cannot be read reaches the view model as a failure")
    func failureReachesTheViewModel() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: nil).viewDidAppear()

        guard case .failure(let message) = viewModel.recipeContent else {
            Issue.record("The failure did not reach the view model.")
            return
        }

        #expect(!message.isEmpty)
    }
}
