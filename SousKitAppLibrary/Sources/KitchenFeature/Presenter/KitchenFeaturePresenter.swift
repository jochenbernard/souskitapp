import CookingFeature
import Foundation
import RecipeFeature
import RecipeLibrary
import SousKit

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol, RecipeFeatureHandler, CookingFeatureHandler {
    private let cookingFeatureFactory: CookingFeatureFactory
    let documentRequest = KitchenDocumentRequest()
    let greetingClock: KitchenGreetingClock
    let handler: KitchenFeatureHandler
    let menuRequest = KitchenMenuRequest()
    private let recipeFeatureFactory: RecipeFeatureFactory
    let recipeRepository: RecipeRepository
    let restorationKeeper: KitchenRestorationKeeper
    let searchIndex = RecipeSearchIndex()
    let thumbnailMemory: RecipeThumbnailMemory
    let viewModel: KitchenFeatureViewModel

    @MainActor
    init(
        cookingFeatureFactory: CookingFeatureFactory,
        greetingClock: KitchenGreetingClock,
        handler: KitchenFeatureHandler,
        recipeFeatureFactory: RecipeFeatureFactory,
        recipeRepository: RecipeRepository,
        restoration: KitchenFeatureRestoration?,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.greetingClock = greetingClock
        self.handler = handler
        self.recipeFeatureFactory = recipeFeatureFactory
        self.recipeRepository = recipeRepository
        self.restorationKeeper = KitchenRestorationKeeper(
            restoration: restoration,
            handler: handler
        )
        self.thumbnailMemory = RecipeThumbnailMemory(shownThumbnails: viewModel.thumbnails)
        self.viewModel = viewModel
    }

    func stackDidAppear() async {
        // What the folders were built from last, symbols aside, or `nil` where none are shown.
        // swiftlint:disable:next discouraged_optional_collection
        var shownRecipes: [ListedRecipe]?

        for await result in await recipeRepository.listedRecipes() {
            switch result {
            case .success(let listedRecipes):
                viewModel.symbols.show(listedRecipes)

                // A listing that only brings a picked symbol redraws the cards showing it, not every folder.
                let unpickedRecipes = listedRecipes.map { listedRecipe in
                    ListedRecipe(entry: listedRecipe.entry, ingredientNames: listedRecipe.ingredientNames)
                }

                guard unpickedRecipes != shownRecipes else {
                    continue
                }

                shownRecipes = unpickedRecipes
                let recipeEntries = listedRecipes.map(\.entry)
                let folder = KitchenFolderTree.folder(at: [], holding: recipeEntries)
                searchIndex.update(listedRecipes)
                viewModel.recipeList = .recipes(folder)
                showSearchResults()
                restore(in: folder, holding: recipeEntries)
                showOpenRecipe(in: recipeEntries)
                documentRequest.recipeEntries = recipeEntries
                openRequestedDocument()

            case .failure(let error):
                shownRecipes = nil
                viewModel.recipeList = .failure(error.localizedDescription)
                restore(in: nil, holding: [])
                // A file the repository holds opens where it sits, as any other file does.
                documentRequest.recipeEntries = []
                openRequestedDocument()
            }
        }
    }

    func didBecomeActive() async {
        // The clock may have moved on, or to another time zone, while the app was away.
        greet()
        await recipeRepository.refresh()
    }

    func didPop(toCount count: Int) {
        guard count < viewModel.pushedScreens.count else {
            return
        }

        stopRestoring()

        // Back pressed with the cook button leaves cooking its recipe to return to.
        guard viewModel.openCooking == nil else {
            pushAgain()
            return
        }

        changePushedScreens(to: Array(viewModel.pushedScreens.prefix(count)))
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

    /// Writes the pushed screens again, so the stack pushes the recipe it already slid away at once, under cooking.
    @MainActor
    private func pushAgain() {
        let pushedScreens = viewModel.pushedScreens

        viewModel.pushedScreens = []
        viewModel.pushedScreens = pushedScreens
    }

    /// Changes the screens on the stack, building the feature for a recipe pushed on top.
    ///
    /// A push builds a fresh feature, so nothing done on a popped screen, such as a scale, comes back. A pop leaves
    /// the recipe it popped in place: clearing it empties that screen while it is still animating away. The next push
    /// replaces it.
    @MainActor
    func changePushedScreens(to pushedScreens: [KitchenScreen]) {
        // A row pressed twice pushes its screen once, keeping the feature the first press built.
        guard pushedScreens != viewModel.pushedScreens else {
            return
        }

        // What a menu asked of a screen it pushed goes with the push, and is not done by a screen pushed later.
        menuRequest.forget()

        let previousTop = viewModel.pushedScreens.last
        viewModel.pushedScreens = pushedScreens
        forgetSearches(offScreen: pushedScreens)

        if case .recipe(let recipeEntry) = pushedScreens.last, pushedScreens.last != previousTop {
            viewModel.openRecipe = makeOpenRecipe(recipeEntry)
        }

        restorationKeeper.save(Self.restoration(of: pushedScreens))
    }

    /// What a cold start opens again for the screens on the stack, as a push opened them, or `nil` for none.
    static func restoration(of pushedScreens: [KitchenScreen]) -> KitchenFeatureRestoration? {
        var folderPath: [String] = []
        var recipeID: String?

        for screen in pushedScreens {
            switch screen {
            case .folder(let path):
                folderPath = path

            case .recipe(let recipeEntry):
                recipeID = recipeEntry.id

            case .document:
                // A file outside the repository is not opened again, as nothing reaches it after a cold start.
                break
            }
        }

        guard !folderPath.isEmpty || recipeID != nil else {
            return nil
        }

        return KitchenFeatureRestoration(folderPath: folderPath, recipeID: recipeID)
    }

    @MainActor
    func makeOpenRecipe(
        _ recipeEntry: RecipeEntry,
        reading recipeRepository: RecipeRepository? = nil,
        restoration: RecipeFeatureRestoration? = nil,
        resumesCooking: Bool = false
    ) -> OpenRecipe {
        // A file outside the kitchen's repository is read through its own.
        let factory = recipeRepository.map(recipeFeatureFactory.reading) ?? recipeFeatureFactory

        return OpenRecipe(
            recipeEntry: recipeEntry,
            feature: factory.makeRecipeFeature(
                recipeEntry: recipeEntry,
                thumbnail: recipeEntry.picture.flatMap({ viewModel.thumbnails[$0] }),
                restoration: restoration,
                resumesCooking: resumesCooking,
                handler: self
            )
        )
    }

    /// Opens cooking from the recipe on top of the stack, unless cooking is already open.
    @MainActor
    private func openCooking(_ recipe: Recipe, isResumed: Bool) {
        let recipeEntry: RecipeEntry

        switch viewModel.pushedScreens.last {
        case .recipe(let pushedEntry), .document(let pushedEntry):
            recipeEntry = pushedEntry

        case .folder, nil:
            return
        }

        guard viewModel.openCooking == nil else {
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
