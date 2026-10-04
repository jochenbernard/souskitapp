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
    private let restorationStore: KitchenRestorationStore
    private let viewModel: KitchenFeatureViewModel

    init(
        cookingFeatureFactory: CookingFeatureFactory,
        handler: KitchenFeatureHandler,
        recipeFeatureFactory: RecipeFeatureFactory,
        recipeRepository: RecipeRepository,
        restorationStore: KitchenRestorationStore,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.handler = handler
        self.recipeFeatureFactory = recipeFeatureFactory
        self.recipeRepository = recipeRepository
        self.restorationStore = restorationStore
        self.viewModel = viewModel
    }

    /// Opens what the kitchen had open when the app last ran: the recipe on the stack, and what its screen had open.
    @MainActor
    func restore() {
        guard let restoration = restorationStore.restoration() else {
            return
        }

        viewModel.screenPath = [.recipe(restoration.recipeEntry)]
        viewModel.openRecipe = makeOpenRecipe(
            restoration.recipeEntry,
            restoration: restoration.recipe,
            resumesCooking: restoration.isCooking
        )
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

        case nil:
            restorationStore.save(nil)
        }
    }

    func didSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        handler.kitchenFeatureDidSelectRecipeRepositoryKind(recipeRepositoryKind)
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
        updateRestoration({ $0.recipe = restoration })
    }

    func cookingFeatureDidExit() {
        closeCooking()
    }

    /// Builds the feature for a recipe pushed on the stack, or keeps the one a recipe already on it has.
    @MainActor
    private func openRecipe(_ recipeEntry: RecipeEntry, isPush: Bool) {
        guard isPush || viewModel.openRecipe?.recipeEntry != recipeEntry else {
            return
        }

        viewModel.openRecipe = makeOpenRecipe(recipeEntry)
        restorationStore.save(KitchenRestoration(recipeEntry: recipeEntry, isCooking: false))
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
        guard case .recipe(let recipeEntry) = viewModel.screenPath.last, viewModel.openCooking == nil else {
            return
        }

        viewModel.openCooking = OpenCooking(
            feature: cookingFeatureFactory.makeCookingFeature(
                recipe: recipe,
                title: recipeEntry.title(of: recipe),
                handler: self
            ),
            isResumed: isResumed
        )
        updateRestoration({ $0.isCooking = true })
    }

    @MainActor
    private func closeCooking() {
        viewModel.openCooking = nil
        updateRestoration({ $0.isCooking = false })
    }

    /// Changes what the store keeps for the recipe on top of the stack.
    @MainActor
    private func updateRestoration(_ update: (inout KitchenRestoration) -> Void) {
        guard
            case .recipe(let recipeEntry) = viewModel.screenPath.last,
            var restoration = restorationStore.restoration(),
            restoration.recipeEntry == recipeEntry
        else {
            return
        }

        update(&restoration)
        restorationStore.save(restoration)
    }
}
