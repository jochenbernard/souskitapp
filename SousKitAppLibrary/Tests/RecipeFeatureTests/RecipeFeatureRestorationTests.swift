@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature restoration", .timeLimit(.minutes(1)))
struct RecipeFeatureRestorationTests {
    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .downloaded
    )

    private static let crepesText = """
        ---
        title: Crepes
        servings: 4
        ---

        Whisk @{4} eggs@ into @{250 g} flour@.
        """

    private let eightServings = RecipeScale(target: .servings, value: 8.0)

    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        handler: RecipeFeatureHandler,
        restoration: RecipeFeatureRestoration? = nil,
        resumesCooking: Bool = false,
        text: String? = Self.crepesText
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: handler,
            parser: SousParser(),
            recipeRepository: RecipeRepositoryStub(text: text),
            restoration: restoration,
            resumesCooking: resumesCooking,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("a restored scale applies to the recipe once it is read")
    func restoredScale() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: RecipeFeatureHandlerSpy(),
            restoration: RecipeFeatureRestoration(scale: eightServings, isScaling: false)
        )

        await presenter.viewDidAppear()

        #expect(viewModel.scaledRecipe?.scale == eightServings)
        #expect(viewModel.scaleText == "8")
    }

    @MainActor
    @Test("a restored scale gives way to the default a cook went back to, on the next read")
    func defaultAfterARestoredScale() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: RecipeFeatureHandlerSpy(),
            restoration: RecipeFeatureRestoration(scale: eightServings, isScaling: false)
        )

        await presenter.viewDidAppear()
        presenter.didTapReset()
        await presenter.viewDidAppear()

        #expect(viewModel.scaledRecipe?.scale == RecipeScale(target: .servings, value: 4.0))
    }

    @MainActor
    @Test("a restored scale sheet opens once the recipe is read, and not before")
    func restoredScaleSheet() async {
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: RecipeFeatureHandlerSpy(),
            restoration: RecipeFeatureRestoration(scale: nil, isScaling: true)
        )

        #expect(!viewModel.isScaling)

        await presenter.viewDidAppear()

        #expect(viewModel.isScaling)
    }

    @MainActor
    @Test("restored cooking resumes once the recipe is read, at the restored scale")
    func restoredCooking() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(
            viewModel: RecipeFeatureViewModel(recipeEntry: crepes),
            handler: handler,
            restoration: RecipeFeatureRestoration(scale: eightServings, isScaling: false),
            resumesCooking: true
        )

        await presenter.viewDidAppear()

        #expect(handler.resumedRecipes.map(\.metadata.servings) == [8.0])
        #expect(handler.cookedRecipes.isEmpty)
    }

    @MainActor
    @Test("restored cooking resumes once, not again when the screen reads the recipe on coming back from it")
    func restoredCookingResumesOnce() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(
            viewModel: RecipeFeatureViewModel(recipeEntry: crepes),
            handler: handler,
            resumesCooking: true
        )

        await presenter.viewDidAppear()
        await presenter.viewDidAppear()

        #expect(handler.resumedRecipes.count == 1)
    }

    @MainActor
    @Test("a recipe that cannot be read resumes nothing")
    func unreadableRecipeResumesNothing() async {
        let handler = RecipeFeatureHandlerSpy()
        let viewModel = RecipeFeatureViewModel(recipeEntry: crepes)
        let presenter = makePresenter(
            viewModel: viewModel,
            handler: handler,
            restoration: RecipeFeatureRestoration(scale: nil, isScaling: true),
            resumesCooking: true,
            text: nil
        )

        await presenter.viewDidAppear()

        #expect(handler.resumedRecipes.isEmpty)
        #expect(!viewModel.isScaling)
    }

    @MainActor
    @Test("a recipe with no steps left resumes nothing")
    func recipeWithoutStepsResumesNothing() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(
            viewModel: RecipeFeatureViewModel(recipeEntry: crepes),
            handler: handler,
            resumesCooking: true,
            text: """
                ---
                title: Crepes
                servings: 4
                ---
                """
        )

        await presenter.viewDidAppear()

        #expect(handler.resumedRecipes.isEmpty)
    }

    @MainActor
    @Test("a new screen reports nothing until a cook changes something")
    func newScreenReportsNothing() async {
        let handler = RecipeFeatureHandlerSpy()

        await makePresenter(viewModel: RecipeFeatureViewModel(recipeEntry: crepes), handler: handler).viewDidAppear()

        #expect(handler.restorations.isEmpty)
    }

    @MainActor
    @Test("opening the scale sheet, scaling and closing it each report what the screen has open")
    func scalingReports() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: RecipeFeatureViewModel(recipeEntry: crepes), handler: handler)

        await presenter.viewDidAppear()
        presenter.didTapScale()
        presenter.didChangeScaleText("8")
        presenter.didChangeIsScaling(false)

        #expect(
            handler.restorations == [
                RecipeFeatureRestoration(scale: nil, isScaling: true),
                RecipeFeatureRestoration(scale: eightServings, isScaling: true),
                RecipeFeatureRestoration(scale: eightServings, isScaling: false)
            ]
        )
    }

    @MainActor
    @Test("going back to the default scale reports no scale, so the file's default applies on a cold start")
    func resetReportsNoScale() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: RecipeFeatureViewModel(recipeEntry: crepes), handler: handler)

        await presenter.viewDidAppear()
        presenter.didStepScale(by: 1.0)
        presenter.didTapReset()

        #expect(handler.restorations.last == RecipeFeatureRestoration(scale: nil, isScaling: false))
    }

    @MainActor
    @Test("another target reports the scale counted that way")
    func targetReports() async {
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: RecipeFeatureViewModel(recipeEntry: crepes), handler: handler)

        await presenter.viewDidAppear()
        presenter.didTapTarget(.multiplier)

        #expect(handler.restorations.last?.scale == RecipeScale(target: .multiplier, value: 1.0))
    }
}
