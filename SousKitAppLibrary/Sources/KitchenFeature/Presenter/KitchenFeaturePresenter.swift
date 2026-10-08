import CookingFeature
import Foundation
import RecipeFeature
import RecipeLibrary
import SettingsFeature
import SousKit

struct KitchenFeaturePresenter:
    KitchenFeaturePresenterProtocol, RecipeFeatureHandler, CookingFeatureHandler, SettingsFeatureHandler {
    private let cookingFeatureFactory: CookingFeatureFactory
    private let handler: KitchenFeatureHandler
    // A class so every copy of the presenter, the sheet's among them, sees the exit waiting.
    private let pendingSettingsExit = PendingSettingsExit()
    private let recipeFeatureFactory: RecipeFeatureFactory
    private let recipeRepository: RecipeRepository
    private let recipeRepositoryKind: RecipeRepositoryKind
    /// How long what a cold start opens stays up before a crash no longer counts against it.
    private let restorationSettleTime: Duration
    private let restorationStore: KitchenRestorationStore
    private let settingsFeatureFactory: SettingsFeatureFactory
    private let terminationObserver: TerminationObserver
    private let timerScheduler: TimerScheduler
    private let viewModel: KitchenFeatureViewModel

    @MainActor
    init(
        cookingFeatureFactory: CookingFeatureFactory,
        handler: KitchenFeatureHandler,
        recipeFeatureFactory: RecipeFeatureFactory,
        recipeRepository: RecipeRepository,
        recipeRepositoryKind: RecipeRepositoryKind,
        restorationSettleTime: Duration,
        restorationStore: KitchenRestorationStore,
        settingsFeatureFactory: SettingsFeatureFactory,
        timerScheduler: TimerScheduler,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.handler = handler
        self.recipeFeatureFactory = recipeFeatureFactory
        self.recipeRepository = recipeRepository
        self.recipeRepositoryKind = recipeRepositoryKind
        self.restorationSettleTime = restorationSettleTime
        self.restorationStore = restorationStore
        self.settingsFeatureFactory = settingsFeatureFactory
        // The store rather than the presenter, which would hold the observer holding it.
        self.terminationObserver = TerminationObserver(onTerminate: { restorationStore.recordTermination() })
        self.timerScheduler = timerScheduler
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        for await result in await recipeRepository.recipeEntries() {
            switch result {
            case .success(let recipeEntries):
                viewModel.recipeList = .recipes(recipeEntries)
                await restore(from: recipeEntries)

            case .failure(let error):
                viewModel.recipeList = .failure(error.localizedDescription)
                await restore(from: [])
            }
        }
    }

    func didBecomeActive() async {
        await recipeRepository.refresh()
    }

    func didEnterBackground() {
        restorationStore.recordUse()
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
            restorationStore.clear()
        }
    }

    func didTapSettings() {
        guard viewModel.screenPath.isEmpty, viewModel.openSettings == nil else {
            return
        }

        openSettings(isRestored: false)
        restorationStore.save(KitchenRestoration(recipeID: nil, isShowingSettings: true))
    }

    func didDismissSettings() {
        // The sheet also reports settings closed from here, which would drop the exit they are waiting to report.
        guard viewModel.openSettings != nil else {
            return
        }

        closeSettings()
    }

    func didFinishDismissingSettings() {
        let exit = pendingSettingsExit.exit
        pendingSettingsExit.exit = nil

        switch exit {
        case .connectRecipeRepository(let recipeRepository):
            handler.kitchenFeatureDidConnectRecipeRepository(recipeRepository)

        case .selectRecipeRepositoryKind(let recipeRepositoryKind):
            handler.kitchenFeatureDidSelectRecipeRepositoryKind(recipeRepositoryKind)

        case .reset:
            handler.kitchenFeatureDidConfirmReset()

        case nil:
            break
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
        updateRestoration({ $0.recipe = restoration })
    }

    func cookingFeatureDidExit() {
        closeCooking()
    }

    func cookingFeatureDidChangeRestoration(_ restoration: CookingFeatureRestoration) {
        updateRestoration({ $0.cooking = restoration })
    }

    func settingsFeatureDidFinish() {
        closeSettings()
    }

    func settingsFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository) {
        closeSettings(exit: .connectRecipeRepository(recipeRepository))
    }

    func settingsFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        guard recipeRepositoryKind != self.recipeRepositoryKind else {
            return
        }

        closeSettings(exit: .selectRecipeRepositoryKind(recipeRepositoryKind))
    }

    func settingsFeatureDidConfirmReset() {
        closeSettings(exit: .reset)
    }

    /// Builds the feature for a recipe pushed on the stack, or keeps the one a recipe already on it has.
    @MainActor
    private func openRecipe(_ recipeEntry: RecipeEntry, isPush: Bool) {
        guard isPush || viewModel.openRecipe?.recipeEntry != recipeEntry else {
            return
        }

        viewModel.openRecipe = makeOpenRecipe(recipeEntry)
        restorationStore.save(KitchenRestoration(recipeID: recipeEntry.id))
    }

    /// Opens what the kitchen had open when the app last ran, or forgets it where it no longer opens or its recipe is
    /// no longer listed.
    @MainActor
    private func restore(from recipeEntries: [RecipeEntry]) async {
        guard viewModel.isRestoring else {
            return
        }

        guard let record = restorationStore.record() else {
            viewModel.isRestoring = false
            return
        }

        let isRestorable = await record.isRestorable(
            at: .now,
            hasRunningTimers: !timerScheduler.currentRunningTimers().isEmpty
        )
        viewModel.isRestoring = false

        guard isRestorable else {
            restorationStore.clear()
            return
        }

        if record.restoration.isShowingSettings {
            openSettings(isRestored: true)
        } else if let recipeEntry = recipeEntries.first(where: { $0.id == record.restoration.recipeID }) {
            viewModel.screenPath = [.recipe(recipeEntry)]
            viewModel.openRecipe = makeOpenRecipe(
                recipeEntry,
                restoration: record.restoration.recipe,
                resumesCooking: record.restoration.cooking != nil
            )
        } else {
            restorationStore.clear()
            return
        }

        restorationStore.beginSettling()
        Task { [restorationSettleTime, restorationStore] in
            try? await Task.sleep(for: restorationSettleTime)
            restorationStore.finishSettling()
        }
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

        // Resumed cooking picks up where it was left, and cooking started from the button starts afresh.
        let cookingRestoration = isResumed ? restorationStore.restoration()?.cooking : nil

        viewModel.openCooking = OpenCooking(
            feature: cookingFeatureFactory.makeCookingFeature(
                recipe: recipe,
                title: recipeEntry.title(of: recipe),
                restoration: cookingRestoration,
                handler: self
            ),
            isResumed: isResumed
        )
        updateRestoration({ $0.cooking = cookingRestoration ?? CookingFeatureRestoration() })
    }

    @MainActor
    private func openSettings(isRestored: Bool) {
        viewModel.openSettings = OpenSettings(
            feature: settingsFeatureFactory.makeSettingsFeature(
                recipeRepositoryName: viewModel.recipeRepositoryName,
                recipeRepositoryKind: recipeRepositoryKind,
                handler: self
            ),
            isRestored: isRestored
        )
    }

    /// Closes the settings, leaving what they asked of the app to report once the sheet is gone.
    @MainActor
    private func closeSettings(exit: SettingsExit? = nil) {
        pendingSettingsExit.exit = exit
        viewModel.openSettings = nil
        restorationStore.clear()
    }

    @MainActor
    private func closeCooking() {
        viewModel.openCooking = nil
        updateRestoration({ $0.cooking = nil })
    }

    /// Changes what the store keeps for the recipe on top of the stack.
    @MainActor
    private func updateRestoration(_ update: (inout KitchenRestoration) -> Void) {
        guard case .recipe(let recipeEntry) = viewModel.screenPath.last else {
            return
        }

        restorationStore.update(recipeID: recipeEntry.id, update)
    }
}
