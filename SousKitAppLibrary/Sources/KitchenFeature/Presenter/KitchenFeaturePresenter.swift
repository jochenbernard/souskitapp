import CookingFeature
import Foundation
import RecipeFeature
import RecipeLibrary
import SousKit

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol, RecipeFeatureHandler, CookingFeatureHandler {
    // One symbol for every recipe, until summaries name their own.
    private static let placeholderSymbol = "fork.knife"

    private let cookingFeatureFactory: CookingFeatureFactory
    let greetingClock: KitchenGreetingClock
    private let handler: KitchenFeatureHandler
    private let recipeFeatureFactory: RecipeFeatureFactory
    private let recipeRepository: RecipeRepository
    private let restorationKeeper: KitchenRestorationKeeper
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
        self.viewModel = viewModel
    }

    func stackDidAppear() async {
        for await result in await recipeRepository.recipeEntries() {
            switch result {
            case .success(let recipeEntries):
                let folder = KitchenFolderTree.folder(at: [], holding: recipeEntries)
                viewModel.recipeList = .recipes(folder)
                restore(in: folder)

            case .failure(let error):
                viewModel.recipeList = .failure(error.localizedDescription)
                restore(in: nil)
            }
        }
    }

    func didBecomeActive() async {
        // The clock may have moved on, or to another time zone, while the app was away.
        greet()
        await recipeRepository.refresh()
    }

    func didPush(_ screen: KitchenScreen, from origin: KitchenScreen?) {
        // A row pressed with the button that opened something over the kitchen pushes nothing under it.
        guard !handler.kitchenFeatureIsCovered else {
            return
        }

        stopRestoring()

        guard let origin else {
            changePushedScreens(to: [screen])
            return
        }

        // A row pressed on a screen already popping pushes nothing.
        guard let index = viewModel.pushedScreens.firstIndex(of: origin) else {
            return
        }

        changePushedScreens(to: Array(viewModel.pushedScreens.prefix(through: index)) + [screen])
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

    func screenDidAppear(_ screen: KitchenScreen) {
        let screensToRestore = restorationKeeper.screensToRestore

        guard !screensToRestore.isEmpty, viewModel.pushedScreens.last == screen else {
            return
        }

        let count = viewModel.pushedScreens.count + 1

        guard count < screensToRestore.count else {
            restorationKeeper.screensToRestore = []
            finishRestoring(screensToRestore)
            return
        }

        viewModel.pushedScreens = Array(screensToRestore.prefix(count))
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
    private func changePushedScreens(to pushedScreens: [KitchenScreen]) {
        // A row pressed twice pushes its screen once, keeping the feature the first press built.
        guard pushedScreens != viewModel.pushedScreens else {
            return
        }

        let previousTop = viewModel.pushedScreens.last
        viewModel.pushedScreens = pushedScreens

        if case .recipe(let recipeEntry) = pushedScreens.last, pushedScreens.last != previousTop {
            viewModel.openRecipe = makeOpenRecipe(recipeEntry)
        }

        restorationKeeper.save(Self.restoration(of: pushedScreens))
    }

    /// What a cold start opens again for the screens on the stack, as a push opened them, or `nil` for none.
    private static func restoration(of pushedScreens: [KitchenScreen]) -> KitchenFeatureRestoration? {
        var folderPath: [String] = []
        var recipeID: String?

        for screen in pushedScreens {
            switch screen {
            case .folder(let path):
                folderPath = path

            case .recipe(let recipeEntry):
                recipeID = recipeEntry.id
            }
        }

        guard !folderPath.isEmpty || recipeID != nil else {
            return nil
        }

        return KitchenFeatureRestoration(folderPath: folderPath, recipeID: recipeID)
    }

    /// Opens what the kitchen was built to open again, as far down as its folders are still listed, and its recipe
    /// where every folder and the recipe still are. What is no longer listed is forgotten.
    ///
    /// - Parameter folder: The top of the repository as it is listed now, or `nil` where it could not be read.
    @MainActor
    private func restore(in folder: KitchenFolder?) {
        guard viewModel.isRestoring, restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        guard let restoration = restorationKeeper.restoration, let folder else {
            viewModel.isRestoring = false
            restorationKeeper.save(nil)
            return
        }

        let folderScreens = restoration.folderPath.indices
            .map({ Array(restoration.folderPath.prefix(through: $0)) })
            .prefix(while: { folder.folder(at: $0) != nil })
            .map(KitchenScreen.folder)
        let card = folder.folder(at: restoration.folderPath)?.cards.first(where: { $0.id == restoration.recipeID })
        let recipeEntry = card?.recipeEntry
        let pushedScreens = folderScreens + (recipeEntry.map({ [KitchenScreen.recipe($0)] }) ?? [])

        guard !pushedScreens.isEmpty else {
            viewModel.isRestoring = false
            restorationKeeper.save(nil)
            return
        }

        guard pushedScreens.count > 1 else {
            finishRestoring(pushedScreens)
            return
        }

        // One at a time: a screen pushed under another without ever appearing loses its large title once uncovered,
        // where it has a subtitle.
        restorationKeeper.screensToRestore = pushedScreens
        viewModel.pushedScreens = [pushedScreens[0]]
    }

    /// Pushes the last of what a cold start opens again, with the recipe on top where there is one.
    ///
    /// - Parameter pushedScreens: Every screen the stack holds once restored.
    @MainActor
    private func finishRestoring(_ pushedScreens: [KitchenScreen]) {
        viewModel.isRestoring = false
        viewModel.pushedScreens = pushedScreens

        if case .recipe(let recipeEntry) = pushedScreens.last {
            viewModel.openRecipe = makeOpenRecipe(
                recipeEntry,
                restoration: restorationKeeper.restoration?.recipe,
                resumesCooking: restorationKeeper.restoration?.cooking != nil
            )
        } else {
            restorationKeeper.save(Self.restoration(of: pushedScreens))
        }

        handler.kitchenFeatureDidRestore()
    }

    /// Leaves a restoration still pushing its screens where it stands, once the cook moves on the stack themselves.
    @MainActor
    private func stopRestoring() {
        guard !restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        restorationKeeper.screensToRestore = []
        viewModel.isRestoring = false
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
        guard case .recipe(let recipeEntry) = viewModel.pushedScreens.last, viewModel.openCooking == nil else {
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

    /// The card a recipe is listed as.
    ///
    /// - Parameter recipeEntry: The recipe.
    /// - Returns: The card.
    static func card(for recipeEntry: RecipeEntry) -> KitchenRecipeCard {
        KitchenRecipeCard(
            recipeEntry: recipeEntry,
            placeholderSymbol: Self.placeholderSymbol,
            placeholderColor: PlaceholderColorPick.color(forTitle: recipeEntry.title)
        )
    }
}
