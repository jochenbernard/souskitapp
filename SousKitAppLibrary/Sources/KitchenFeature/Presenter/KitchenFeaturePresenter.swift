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
    private let restorationKeeper: KitchenRestorationKeeper
    private let viewModel: KitchenFeatureViewModel

    @MainActor
    init(
        cookingFeatureFactory: CookingFeatureFactory,
        handler: KitchenFeatureHandler,
        recipeFeatureFactory: RecipeFeatureFactory,
        recipeRepository: RecipeRepository,
        restoration: KitchenFeatureRestoration?,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.handler = handler
        self.recipeFeatureFactory = recipeFeatureFactory
        self.recipeRepository = recipeRepository
        self.restorationKeeper = KitchenRestorationKeeper(
            restoration: restoration,
            handler: handler
        )
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        for await result in await recipeRepository.recipeEntries() {
            switch result {
            case .success(let recipeEntries):
                viewModel.recipeList = .recipes(recipeEntries)
                restore(from: recipeEntries)

            case .failure(let error):
                viewModel.recipeList = .failure(error.localizedDescription)
                restore(from: [])
            }
        }
    }

    func didBecomeActive() async {
        await recipeRepository.refresh()
    }

    func didChangePushedScreen(_ screen: KitchenScreen?) {
        // A row pressed with the button that opened something over the kitchen pushes nothing under it.
        guard screen == nil || !handler.kitchenFeatureIsCovered else {
            return
        }

        // Back pressed with the cook button leaves cooking its recipe to return to.
        guard screen != nil || viewModel.openCooking == nil else {
            pushAgain()
            return
        }

        // A push builds a fresh feature, so nothing done on a popped screen, such as a scale, comes back.
        let isPush = viewModel.pushedScreen == nil

        viewModel.pushedScreen = screen

        // A pop leaves the screen it popped in place: clearing it empties that screen while it
        // is still animating away. The next push replaces it.
        switch screen {
        case .recipe(let recipeEntry):
            openRecipe(recipeEntry, isPush: isPush)

        case nil:
            restorationKeeper.save(nil)
        }
    }

    func didDismissCooking() {
        closeCooking()
    }

    func recipeFeatureDidStartCooking(recipe: Recipe) {
        openCooking(recipe, isResumed: false)
    }

    func recipeFeatureDidResumeCooking(recipe: Recipe) {
        openCooking(recipe, isResumed: true)
    }

    func recipeFeatureDidChangeRestoration(_ restoration: RecipeFeatureRestoration) {
        restorationKeeper.update({ $0.recipe = restoration })
    }

    func cookingFeatureDidExit() {
        closeCooking()
    }

    func cookingFeatureDidChangeRestoration(_ restoration: CookingFeatureRestoration) {
        restorationKeeper.update({ $0.cooking = restoration })
    }

    /// Writes the pushed screen again, so the stack pushes the recipe it already slid away at once, under cooking.
    @MainActor
    private func pushAgain() {
        let pushedScreen = viewModel.pushedScreen

        viewModel.pushedScreen = nil
        viewModel.pushedScreen = pushedScreen
    }

    /// Builds the feature for a recipe pushed on the stack, or keeps the one a recipe already on it has.
    @MainActor
    private func openRecipe(_ recipeEntry: RecipeEntry, isPush: Bool) {
        guard isPush || viewModel.openRecipe?.recipeEntry != recipeEntry else {
            return
        }

        viewModel.openRecipe = makeOpenRecipe(recipeEntry)
        restorationKeeper.save(KitchenFeatureRestoration(recipeID: recipeEntry.id))
    }

    /// Opens what the kitchen was built to open again, or forgets it where its recipe is no longer listed.
    @MainActor
    private func restore(from recipeEntries: [RecipeEntry]) {
        guard viewModel.isRestoring else {
            return
        }

        viewModel.isRestoring = false

        guard
            let restoration = restorationKeeper.restoration,
            let recipeEntry = recipeEntries.first(where: { $0.id == restoration.recipeID })
        else {
            restorationKeeper.save(nil)
            return
        }

        viewModel.pushedScreen = .recipe(recipeEntry)
        viewModel.openRecipe = makeOpenRecipe(
            recipeEntry,
            restoration: restoration.recipe,
            resumesCooking: restoration.cooking != nil
        )
        handler.kitchenFeatureDidRestore()
    }

    @MainActor
    private func makeOpenRecipe(
        _ recipeEntry: RecipeEntry,
        restoration: RecipeFeatureRestoration? = nil,
        resumesCooking: Bool = false
    ) -> OpenRecipe {
        OpenRecipe(
            recipeEntry: recipeEntry,
            feature: recipeFeatureFactory.makeRecipeFeature(
                recipeEntry: recipeEntry,
                restoration: restoration,
                resumesCooking: resumesCooking,
                handler: self
            )
        )
    }

    /// Opens cooking from the recipe on top of the stack, unless cooking is already open.
    @MainActor
    private func openCooking(_ recipe: Recipe, isResumed: Bool) {
        guard case .recipe(let recipeEntry) = viewModel.pushedScreen, viewModel.openCooking == nil else {
            return
        }

        // Resumed cooking picks up where it was left, and cooking started from the button starts afresh.
        let cookingRestoration = isResumed ? restorationKeeper.restoration?.cooking : nil

        viewModel.openCooking = OpenCooking(
            feature: cookingFeatureFactory.makeCookingFeature(
                recipe: recipe,
                title: recipeEntry.title(of: recipe),
                restoration: cookingRestoration,
                handler: self
            ),
            isResumed: isResumed
        )
        restorationKeeper.update({ $0.cooking = cookingRestoration ?? CookingFeatureRestoration() })
    }

    @MainActor
    private func closeCooking() {
        viewModel.openCooking = nil
        restorationKeeper.update({ $0.cooking = nil })
    }
}
