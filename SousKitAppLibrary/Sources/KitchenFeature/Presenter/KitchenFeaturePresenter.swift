import CookingFeature
import Foundation
import RecipeFeature
import RecipeLibrary
import SousKit

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol, RecipeFeatureHandler, CookingFeatureHandler {
    private let cookingFeatureFactory: CookingFeatureFactory
    private let handler: KitchenFeatureHandler
    private let recipeFeatureFactory: RecipeFeatureFactory
    private let recipeRepository: RecipeRepository
    private let viewModel: KitchenFeatureViewModel

    init(
        cookingFeatureFactory: CookingFeatureFactory,
        handler: KitchenFeatureHandler,
        recipeFeatureFactory: RecipeFeatureFactory,
        recipeRepository: RecipeRepository,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.handler = handler
        self.recipeFeatureFactory = recipeFeatureFactory
        self.recipeRepository = recipeRepository
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        for await result in await recipeRepository.recipeEntries() {
            switch result {
            case .success(let recipeEntries):
                viewModel.recipeList = .recipes(recipeEntries)

            case .failure(let error):
                viewModel.recipeList = .failure(error.localizedDescription)
            }
        }
    }

    func didBecomeActive() async {
        await recipeRepository.refresh()
    }

    func didChangeScreenPath(_ screenPath: [KitchenScreen]) {
        // A push builds a fresh feature, so nothing done on a popped screen, such as a scale, comes back.
        let isPush = screenPath.count > viewModel.screenPath.count

        viewModel.screenPath = screenPath

        // A pop leaves the screen it popped in place: clearing it empties that screen while it
        // is still animating away. The next push replaces it.
        switch screenPath.last {
        case .recipe(let recipeEntry):
            openRecipe(recipeEntry, isPush: isPush)

        case .cooking(let recipe):
            openCooking(recipe, isPush: isPush)

        case nil:
            break
        }
    }

    func didTapReset() {
        viewModel.isConfirmingReset = true
    }

    func didChangeIsConfirmingReset(_ isConfirming: Bool) {
        viewModel.isConfirmingReset = isConfirming
    }

    func didConfirmReset() {
        viewModel.isConfirmingReset = false
        handler.kitchenFeatureDidConfirmReset()
    }

    func recipeFeatureDidStartCooking(recipe: Recipe) {
        guard case .recipe = viewModel.screenPath.last else {
            return
        }

        didChangeScreenPath(viewModel.screenPath + [.cooking(recipe)])
    }

    func cookingFeatureDidExit() {
        guard case .cooking = viewModel.screenPath.last else {
            return
        }

        didChangeScreenPath(Array(viewModel.screenPath.dropLast()))
    }

    /// Builds the feature for a recipe pushed on the stack, or keeps the one a recipe already on it has,
    /// such as the recipe a popped cooking screen uncovers.
    @MainActor
    private func openRecipe(_ recipeEntry: RecipeEntry, isPush: Bool) {
        guard isPush || viewModel.openRecipe?.recipeEntry != recipeEntry else {
            return
        }

        viewModel.openRecipe = OpenRecipe(
            recipeEntry: recipeEntry,
            feature: recipeFeatureFactory.makeRecipeFeature(
                recipeEntry: recipeEntry,
                handler: self
            )
        )
    }

    /// Builds the feature for a recipe pushed on the stack to cook from, or keeps the one already on it.
    @MainActor
    private func openCooking(_ recipe: Recipe, isPush: Bool) {
        guard isPush || viewModel.openCooking?.recipe != recipe else {
            return
        }

        viewModel.openCooking = OpenCooking(
            recipe: recipe,
            feature: cookingFeatureFactory.makeCookingFeature(
                recipe: recipe,
                handler: self
            )
        )
    }
}
