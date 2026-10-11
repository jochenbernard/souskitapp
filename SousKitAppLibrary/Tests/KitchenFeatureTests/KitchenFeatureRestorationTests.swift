@testable import CookingFeature
import Foundation
@testable import KitchenFeature
@testable import RecipeFeature
import RecipeLibrary
import RecipeScaling
import SousKit
import Testing

@Suite("Kitchen feature restoration", .timeLimit(.minutes(1)))
struct KitchenFeatureRestorationTests {
    /// A kitchen built to open a restoration again, with what it reported.
    private struct RestoredKitchen {
        let viewModel: KitchenFeatureViewModel
        let presenter: KitchenFeaturePresenter
        let handler: KitchenFeatureHandlerStub
    }

    private let parser = SousParser()

    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .notDownloaded
    )

    @MainActor
    private func makeViewModel(isRestoring: Bool = false) -> KitchenFeatureViewModel {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        viewModel.isRestoring = isRestoring

        return viewModel
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        handler: KitchenFeatureHandlerStub
    ) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler
        )
    }

    /// Builds a kitchen to open the restoration again, whose repository lists each of the results in turn.
    @MainActor
    private func restore(
        _ restoration: KitchenFeatureRestoration,
        listing results: [Result<[RecipeEntry], Error>]
    ) async -> RestoredKitchen {
        let handler = KitchenFeatureHandlerStub(restoration: restoration)
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            recipeRepository: recipeRepository,
            restoration: restoration
        )

        for result in results {
            recipeRepository.send(result)
        }

        recipeRepository.finish()
        await presenter.viewDidAppear()

        return RestoredKitchen(
            viewModel: viewModel,
            presenter: presenter,
            handler: handler
        )
    }

    @MainActor
    @Test("a recipe pushed on the stack is reported for the next cold start")
    func pushReportsTheRecipe() {
        let handler = KitchenFeatureHandlerStub()

        makePresenter(viewModel: makeViewModel(), handler: handler).didChangePushedScreen(.recipe(crepes))

        #expect(handler.restoration == KitchenFeatureRestoration(recipeID: crepes.id))
    }

    @MainActor
    @Test("popping back to the recipe list reports nothing open")
    func popReportsNothingOpen() {
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.didChangePushedScreen(nil)

        #expect(handler.restoration == nil)
    }

    @MainActor
    @Test("what the recipe screen reports is reported beside the recipe")
    func recipeReportIsPassedOn() {
        let restoration = RecipeFeatureRestoration(
            scale: RecipeScale(target: .multiplier, value: 2.0),
            isScaling: true
        )
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.recipeFeatureDidChangeRestoration(restoration)

        #expect(handler.restoration?.recipe == restoration)
    }

    @MainActor
    @Test("a report with no recipe on the stack reports nothing")
    func reportWithoutARecipeReportsNothing() {
        let handler = KitchenFeatureHandlerStub()

        makePresenter(viewModel: makeViewModel(), handler: handler).recipeFeatureDidChangeRestoration(
            RecipeFeatureRestoration(scale: nil, isScaling: true)
        )

        #expect(handler.restoration == nil)
    }

    @MainActor
    @Test("cooking is reported while it is open, and gone once it is exited")
    func cookingIsReportedUntilExited() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(handler.restoration?.cooking == CookingFeatureRestoration())

        presenter.cookingFeatureDidExit()

        #expect(handler.restoration == KitchenFeatureRestoration(recipeID: crepes.id))
    }

    @MainActor
    @Test("cooking dismissed is reported gone")
    func dismissedCookingIsReportedGone() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.didDismissCooking()

        #expect(handler.restoration == KitchenFeatureRestoration(recipeID: crepes.id))
    }

    @MainActor
    @Test("the steps cooking ticks off are reported, and gone once cooking is exited")
    func tickedStepsAreReportedUntilExited() {
        let cooking = CookingFeatureRestoration(completedStepNumbers: [1])
        let handler = KitchenFeatureHandlerStub()
        let presenter = makePresenter(viewModel: makeViewModel(), handler: handler)

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.recipeFeatureDidStartCooking(recipe: parser.parseRecipe("Whisk it.").value)
        presenter.cookingFeatureDidChangeRestoration(cooking)

        #expect(handler.restoration?.cooking == cooking)

        presenter.cookingFeatureDidExit()

        #expect(handler.restoration?.cooking == nil)
    }

    @MainActor
    @Test("a kitchen restored opens the recipe as the repository lists it now, with a feature to render it")
    func restoreOpensTheListedRecipe() async {
        let listedCrepes = RecipeEntry(
            id: crepes.id,
            name: crepes.name,
            availability: .downloaded
        )
        let restoration = KitchenFeatureRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration())

        let kitchen = await restore(restoration, listing: [.success([listedCrepes])])

        #expect(kitchen.viewModel.pushedScreen == .recipe(listedCrepes))
        #expect(kitchen.viewModel.openRecipe?.recipeEntry == listedCrepes)
        #expect(kitchen.viewModel.openCooking == nil)
        #expect(!kitchen.viewModel.isRestoring)
        #expect(kitchen.handler.restoreCount == 1)
        #expect(kitchen.handler.restoration == restoration)
    }

    @MainActor
    @Test("a kitchen whose recipe is no longer listed stays on its recipe list and reports nothing open")
    func restoreWithoutTheRecipe() async {
        let restoration = KitchenFeatureRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration())

        let kitchen = await restore(restoration, listing: [.success([]), .success([crepes])])

        #expect(kitchen.viewModel.pushedScreen == nil)
        #expect(kitchen.viewModel.openRecipe == nil)
        #expect(!kitchen.viewModel.isRestoring)
        #expect(kitchen.handler.restoreCount == 0)
        #expect(kitchen.handler.restoration == nil)
    }

    @MainActor
    @Test("a kitchen whose recipes cannot be listed stays on its recipe list and reports nothing open")
    func restoreAfterAFailure() async {
        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id),
            listing: [.failure(CocoaError(.fileReadNoSuchFile)), .success([crepes])]
        )

        #expect(kitchen.viewModel.pushedScreen == nil)
        #expect(kitchen.handler.restoreCount == 0)
        #expect(kitchen.handler.restoration == nil)
    }

    @MainActor
    @Test("a kitchen built to open nothing again stays on its recipe list")
    func restoreWithNothingKept() async {
        let handler = KitchenFeatureHandlerStub()
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel()
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            recipeRepository: recipeRepository
        )

        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await presenter.viewDidAppear()

        #expect(viewModel.pushedScreen == nil)
        #expect(viewModel.openRecipe == nil)
        #expect(handler.restoreCount == 0)
    }

    @MainActor
    @Test("a list arriving while the restored recipe is open leaves it open as it is")
    func laterListKeepsTheRestoredRecipe() async {
        let renamedCrepes = RecipeEntry(
            id: crepes.id,
            name: "crepes suzette",
            availability: crepes.availability
        )

        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id),
            listing: [.success([crepes]), .success([renamedCrepes])]
        )

        #expect(kitchen.viewModel.pushedScreen == .recipe(crepes))
        #expect(kitchen.viewModel.openRecipe?.recipeEntry == crepes)
        #expect(kitchen.handler.restoreCount == 1)
    }

    @MainActor
    @Test("cooking resumed opens over the kitchen as resumed, and stays reported")
    func resumedCookingOpens() async {
        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()),
            listing: [.success([crepes])]
        )
        kitchen.presenter.recipeFeatureDidResumeCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(kitchen.viewModel.openCooking?.isResumed == true)
        #expect(kitchen.handler.restoration?.cooking != nil)
    }

    @MainActor
    @Test("cooking resumed keeps the steps it had ticked off")
    func resumedCookingKeepsItsTickedSteps() async {
        let cooking = CookingFeatureRestoration(completedStepNumbers: [1])

        let kitchen = await restore(
            KitchenFeatureRestoration(recipeID: crepes.id, cooking: cooking),
            listing: [.success([crepes])]
        )
        kitchen.presenter.recipeFeatureDidResumeCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(kitchen.handler.restoration?.cooking == cooking)
    }

    @MainActor
    @Test("cooking started from the button opens as started, not resumed")
    func startedCookingIsNotResumed() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: KitchenFeatureHandlerStub())

        presenter.didChangePushedScreen(.recipe(crepes))
        presenter.recipeFeatureDidStartCooking(recipe: parser.parseRecipe("Whisk it.").value)

        #expect(viewModel.openCooking?.isResumed == false)
    }
}
