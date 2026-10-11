@testable import KitchenFeature
import Observation
import os
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature stack", .timeLimit(.minutes(1)))
struct KitchenFeatureStackTests {
    private let parser = SousParser()

    private func recipeEntry(named name: String) -> RecipeEntry {
        RecipeEntry(
            id: name,
            name: name,
            availability: .downloaded
        )
    }

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    }

    @MainActor
    private func makePresenter(viewModel: KitchenFeatureViewModel) -> KitchenFeaturePresenter {
        .stubbed(
            viewModel: viewModel,
            parser: parser
        )
    }

    /// Whether the action gives the view model a new value at the key path, rather than leaving it be.
    ///
    /// A feature has no identity to compare, so what is watched is whether one is built at all.
    @MainActor
    private func replaces<Value>(
        _ keyPath: KeyPath<KitchenFeatureViewModel, Value>,
        in viewModel: KitchenFeatureViewModel,
        when action: () -> Void
    ) -> Bool {
        let isReplaced = OSAllocatedUnfairLock(initialState: false)

        withObservationTracking(
            { _ = viewModel[keyPath: keyPath] },
            onChange: { isReplaced.withLock({ $0 = true }) }
        )
        action()

        return isReplaced.withLock({ $0 })
    }

    @MainActor
    @Test("a recipe pushed on the stack reaches the view model with a feature to render it")
    func recipePathReachesTheViewModel() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didChangeScreenPath([.recipe(crepes)])

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("popping leaves the recipe in place, so it has something to animate away")
    func poppingKeepsTheOpenRecipe() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.didChangeScreenPath([])

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("pushing another recipe after a pop replaces the one left behind")
    func pushingAfterAPopReplacesTheOpenRecipe() {
        let crepes = recipeEntry(named: "crepes")
        let brioche = recipeEntry(named: "brioche")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.didChangeScreenPath([])
        presenter.didChangeScreenPath([.recipe(brioche)])

        #expect(viewModel.openRecipe?.recipeEntry == brioche)
    }

    @MainActor
    @Test("the stack set again as it stands keeps the feature already built for it")
    func settingTheSameStackKeepsItsFeature() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])

        #expect(!replaces(\.openRecipe, in: viewModel) {
            presenter.didChangeScreenPath([.recipe(crepes)])
        })
    }

    @MainActor
    @Test("a recipe pushed again after a pop gets a feature of its own, not the one left behind")
    func pushingTheSameRecipeAfterAPopBuildsItsFeature() {
        let crepes = recipeEntry(named: "crepes")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.didChangeScreenPath([])

        #expect(replaces(\.openRecipe, in: viewModel) {
            presenter.didChangeScreenPath([.recipe(crepes)])
        })
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("cooking a recipe opens it over the kitchen with a feature to render it, leaving the stack as it was")
    func cookingOpensTheCookingScreen() {
        let crepes = recipeEntry(named: "crepes")
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openCooking != nil)
    }

    @MainActor
    @Test("cooking reported again while cooking opens nothing new")
    func cookingTwiceOpensOnce() {
        let crepes = recipeEntry(named: "crepes")
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(!replaces(\.openCooking, in: viewModel) {
            presenter.recipeFeatureDidStartCooking(recipe: recipe)
        })
    }

    @MainActor
    @Test("cooking reported with no recipe on top of the stack opens nothing")
    func cookingWithoutARecipeOpensNothing() {
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(viewModel.openCooking == nil)
    }

    @MainActor
    @Test("exiting the cooking screen closes it and uncovers the recipe with its feature")
    func exitingCookingUncoversTheRecipe() {
        let crepes = recipeEntry(named: "crepes")
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(!replaces(\.openRecipe, in: viewModel) {
            presenter.cookingFeatureDidExit()
        })
        #expect(viewModel.openCooking == nil)
        #expect(viewModel.screenPath == [.recipe(crepes)])
    }

    @MainActor
    @Test("the cooking screen dismissed closes it")
    func dismissingCookingClosesIt() {
        let crepes = recipeEntry(named: "crepes")
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.didDismissCooking()

        #expect(viewModel.openCooking == nil)
    }

    @MainActor
    @Test("cooking the same recipe again after an exit gets a feature of its own")
    func cookingAgainBuildsItsFeature() {
        let crepes = recipeEntry(named: "crepes")
        let recipe = parser.parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        let firstVisit = viewModel.openCooking?.id
        presenter.cookingFeatureDidExit()
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(viewModel.openCooking != nil)
        #expect(viewModel.openCooking?.id != firstVisit)
    }
}
