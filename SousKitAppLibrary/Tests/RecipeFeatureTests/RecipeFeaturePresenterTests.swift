@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature presenter", .timeLimit(.minutes(1)))
struct RecipeFeaturePresenterTests {
    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .downloaded
    )

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

        guard case .recipe(let recipe) = viewModel.recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return
        }

        #expect(recipe.metadata.title == "Crepes")
        #expect(recipe.metadata.servings == 4.0)
        #expect(recipe.ingredients.map(\.name) == ["eggs"])
        #expect(recipe.cookware.map(\.name) == ["mixing bowl"])
        #expect(recipe.steps.count == 1)
    }

    @MainActor
    @Test("an empty recipe reaches the view model holding nothing")
    func emptyRecipeReachesTheViewModel() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)

        await makePresenter(viewModel: viewModel, recipeText: "").viewDidAppear()

        guard case .recipe(let recipe) = viewModel.recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return
        }

        #expect(recipe.steps.isEmpty)
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
    @Test("tapping cook reports the recipe that was read")
    func cookingReportsTheRecipe() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            recipeText: """
                ---
                title: Crepes
                ---

                Whisk it.
                """
        )

        await presenter.viewDidAppear()
        presenter.didTapCook()

        #expect(handler.cookedRecipes.map(\.metadata.title) == ["Crepes"])
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
