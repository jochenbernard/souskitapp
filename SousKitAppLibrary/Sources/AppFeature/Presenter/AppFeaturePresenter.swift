import CookingFeature
import Foundation
import KitchenFeature
import OnboardingFeature
import RecipeLibrary
import SettingsFeature

/// Moves the app between onboarding and the kitchen, the kitchen between the kinds of recipe repository, opens the
/// settings over it, and opens what the app had open again on a cold start.
final class AppFeaturePresenter:
    AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler, SettingsFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let preferredScaleStore: UserDefaultsPreferredScaleStore
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore
    /// How long what a cold start opens stays up before a crash no longer counts against it.
    private let restorationSettleTime: Duration
    private let restorationStore: AppRestorationStore
    private let settingsFeatureFactory: SettingsFeatureFactory
    private let terminationObserver: TerminationObserver
    private let timerScheduler: TimerScheduler

    /// What the user knows the recipes the kitchen reads by, which the settings show.
    private var recipeRepositoryName = ""

    /// Whether a cold start found the settings open, and has yet to open them again.
    private var restoresSettings = false

    @MainActor
    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        mockRecipeRepository: RecipeRepository,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        preferredScaleStore: UserDefaultsPreferredScaleStore,
        recipeRepositoryKindStore: RecipeRepositoryKindStore,
        recipeRepositoryStore: RecipeRepositoryStore,
        restorationSettleTime: Duration,
        restorationStore: AppRestorationStore,
        settingsFeatureFactory: SettingsFeatureFactory,
        timerScheduler: TimerScheduler
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.mockRecipeRepository = mockRecipeRepository
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepositoryKindStore = recipeRepositoryKindStore
        self.recipeRepositoryStore = recipeRepositoryStore
        self.restorationSettleTime = restorationSettleTime
        self.restorationStore = restorationStore
        self.settingsFeatureFactory = settingsFeatureFactory
        // The store rather than the presenter, which would hold the observer holding it.
        self.terminationObserver = TerminationObserver(onTerminate: { restorationStore.recordTermination() })
        self.timerScheduler = timerScheduler
    }

    /// Builds the view model a cold start opens on: the screen the remembered kind of repository calls for, with what
    /// the app had open when it last ran where that still opens.
    ///
    /// - Returns: The view model, which this presenter writes from now on.
    @MainActor
    func makeViewModel() -> AppFeatureViewModel {
        let restoration = takeRestoration()
        let screen = makeScreen(restoration: restoration?.kitchen)
        let launched = AppFeatureViewModel(screen: screen)
        viewModel = launched

        // Onboarding forgot it all, and opens nothing again.
        guard let restoration, case .kitchen = screen else {
            return launched
        }

        // Opened once the view is up: a sheet already open on the first render slides in whatever the transaction.
        restoresSettings = restoration.isShowingSettings

        // The kitchen reports when it has opened its own, once its recipe is listed.
        if restoration.kitchen == nil {
            settle()
        }

        return launched
    }

    func viewDidAppear() {
        guard restoresSettings else {
            return
        }

        restoresSettings = false
        openSettings(id: UUID(), isRestored: true)
    }

    func didTapSettings() {
        // A press landing after a recipe row's opens nothing over the recipe, whose screen has no such button.
        guard viewModel?.openSettings == nil, restorationStore.record()?.restoration.kitchen == nil else {
            return
        }

        openSettings(id: UUID(), isRestored: false)
        restorationStore.update({ $0.isShowingSettings = true })
    }

    func didDismissSettings() {
        closeSettings()
    }

    func didEnterBackground() {
        restorationStore.recordUse()
    }

    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository) {
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository)
    }

    func onboardingFeatureDidChooseMockRecipes() {
        recipeRepositoryKindStore.remember(.mock)
        viewModel?.screen = makeScreen()
    }

    var kitchenFeatureIsCovered: Bool {
        viewModel?.openSettings != nil
    }

    func kitchenFeatureDidChangeRestoration(_ restoration: KitchenFeatureRestoration?) {
        restorationStore.update({ $0.kitchen = restoration })
    }

    func kitchenFeatureDidRestore() {
        settle()
    }

    func settingsFeatureDidFinish() {
        closeSettings()
    }

    func settingsFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository) {
        // A folder picked over the mock recipes is read from now on.
        recipeRepositoryKindStore.remember(.files)
        replaceKitchen(recipeRepository: recipeRepository)
    }

    func settingsFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        guard recipeRepositoryKind != recipeRepositoryKindStore.recipeRepositoryKind else {
            return
        }

        recipeRepositoryKindStore.remember(recipeRepositoryKind)

        if let recipeRepository = makeRecipeRepository(of: recipeRepositoryKind) {
            replaceKitchen(recipeRepository: recipeRepository)
        } else {
            // The folder is still to be picked, on onboarding, which the settings do not stay open over.
            closeSettings()
            viewModel?.screen = makeScreen(recipeRepository: nil)
        }
    }

    func settingsFeatureDidConfirmReset() {
        preferredScaleStore.clear()
        recipeRepositoryKindStore.clear()
        recipeRepositoryStore.clear()
        closeSettings()
        viewModel?.screen = makeScreen()
    }

    /// What a cold start opens again, unsettled from here on, or `nil` with what no longer opens forgotten.
    @MainActor
    private func takeRestoration() -> AppRestoration? {
        guard
            let record = restorationStore.record(),
            record.isRestorable(
                at: .now,
                hasRunningTimers: !timerScheduler.currentRunningTimers().isEmpty
            )
        else {
            restorationStore.clear()
            return nil
        }

        // Settling begins before anything opens, so a crash while opening it still counts against it.
        restorationStore.beginSettling()

        return record.restoration
    }

    /// Counts what a cold start opened as settled once it has stayed up for a while.
    @MainActor
    private func settle() {
        Task { [restorationSettleTime, restorationStore] in
            try? await Task.sleep(for: restorationSettleTime)
            restorationStore.finishSettling()
        }
    }

    @MainActor
    private func makeRecipeRepository(of recipeRepositoryKind: RecipeRepositoryKind) -> RecipeRepository? {
        switch recipeRepositoryKind {
        case .files: recipeRepositoryStore.makeRecipeRepository()
        case .mock: mockRecipeRepository
        }
    }

    /// The screen the remembered kind of repository calls for: the kitchen reading it, or onboarding where the folder
    /// is to be picked.
    @MainActor
    private func makeScreen(restoration: KitchenFeatureRestoration? = nil) -> AppScreen {
        makeScreen(
            recipeRepository: makeRecipeRepository(of: recipeRepositoryKindStore.recipeRepositoryKind),
            restoration: restoration
        )
    }

    @MainActor
    private func makeScreen(
        recipeRepository: RecipeRepository?,
        restoration: KitchenFeatureRestoration? = nil
    ) -> AppScreen {
        guard let recipeRepository else {
            // What the app had open belongs to a kitchen that is gone.
            restorationStore.clear()

            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        recipeRepositoryName = recipeRepository.name

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeRepository: recipeRepository,
                restoration: restoration,
                handler: self
            ),
            id: UUID()
        )
    }

    /// Puts a kitchen reading another repository under the settings, which stay open and show that repository.
    @MainActor
    private func replaceKitchen(recipeRepository: RecipeRepository) {
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository)
        // What the replaced kitchen had open is gone with it, and would keep the settings shut on the new one's list.
        restorationStore.update({ $0.kitchen = nil })

        guard let settings = viewModel?.openSettings else {
            return
        }

        openSettings(id: settings.id, isRestored: settings.isRestored)
    }

    /// Builds the settings for the repository the kitchen reads now.
    ///
    /// - Parameters:
    ///   - id: The visit the settings belong to, which is the one already open when they are built again.
    ///   - isRestored: Whether a cold start opens them.
    @MainActor
    private func openSettings(id: UUID, isRestored: Bool) {
        viewModel?.openSettings = OpenSettings(
            id: id,
            feature: settingsFeatureFactory.makeSettingsFeature(
                recipeRepositoryName: recipeRepositoryName,
                recipeRepositoryKind: recipeRepositoryKindStore.recipeRepositoryKind,
                handler: self
            ),
            isRestored: isRestored
        )
    }

    @MainActor
    private func closeSettings() {
        viewModel?.openSettings = nil
        restorationStore.update({ $0.isShowingSettings = false })
    }
}
