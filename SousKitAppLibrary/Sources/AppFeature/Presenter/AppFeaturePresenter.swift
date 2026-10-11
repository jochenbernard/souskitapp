import Foundation
import KitchenFeature
import OnboardingFeature
import RecipeLibrary
import SettingsFeature

/// Moves the app between onboarding and the kitchen, the kitchen between the kinds of recipe repository, and opens the
/// settings over it.
final class AppFeaturePresenter:
    AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler, SettingsFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let kitchenRestorationStore: KitchenRestorationStore
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let preferredScaleStore: UserDefaultsPreferredScaleStore
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore
    private let settingsFeatureFactory: SettingsFeatureFactory

    /// What the user knows the recipes the kitchen reads by, which the settings show.
    private var recipeRepositoryName = ""

    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        kitchenRestorationStore: KitchenRestorationStore,
        mockRecipeRepository: RecipeRepository,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        preferredScaleStore: UserDefaultsPreferredScaleStore,
        recipeRepositoryKindStore: RecipeRepositoryKindStore,
        recipeRepositoryStore: RecipeRepositoryStore,
        settingsFeatureFactory: SettingsFeatureFactory
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.kitchenRestorationStore = kitchenRestorationStore
        self.mockRecipeRepository = mockRecipeRepository
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepositoryKindStore = recipeRepositoryKindStore
        self.recipeRepositoryStore = recipeRepositoryStore
        self.settingsFeatureFactory = settingsFeatureFactory
    }

    /// The screen the remembered kind of repository calls for: the kitchen reading it, or onboarding where the folder
    /// is to be picked.
    ///
    /// - Returns: The screen, reporting to this presenter.
    @MainActor
    func makeScreen() -> AppScreen {
        makeScreen(recipeRepository: makeRecipeRepository(of: recipeRepositoryKindStore.recipeRepositoryKind))
    }

    func didDismissSettings() {
        closeSettings()
    }

    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository) {
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository)
    }

    func onboardingFeatureDidChooseMockRecipes() {
        recipeRepositoryKindStore.remember(.mock)
        viewModel?.screen = makeScreen()
    }

    func kitchenFeatureDidTapSettings() {
        guard viewModel?.openSettings == nil else {
            return
        }

        openSettings(id: UUID(), isRestored: false)
        kitchenRestorationStore.saveSettings()
    }

    func kitchenFeatureDidRestoreSettings() {
        openSettings(id: UUID(), isRestored: true)
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

    @MainActor
    private func makeRecipeRepository(of recipeRepositoryKind: RecipeRepositoryKind) -> RecipeRepository? {
        switch recipeRepositoryKind {
        case .files: recipeRepositoryStore.makeRecipeRepository()
        case .mock: mockRecipeRepository
        }
    }

    @MainActor
    private func makeScreen(recipeRepository: RecipeRepository?) -> AppScreen {
        guard let recipeRepository else {
            // What the last kitchen had open belongs to recipes the next one may not read.
            kitchenRestorationStore.clear()

            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        recipeRepositoryName = recipeRepository.name

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeRepository: recipeRepository,
                handler: self
            ),
            id: UUID()
        )
    }

    /// Puts a kitchen reading another repository under the settings, which stay open and show that repository.
    @MainActor
    private func replaceKitchen(recipeRepository: RecipeRepository) {
        // Forgotten while the kitchen is built, so it opens on its recipe list rather than as a cold start would.
        kitchenRestorationStore.clear()
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository)

        guard let settings = viewModel?.openSettings else {
            return
        }

        openSettings(id: settings.id, isRestored: settings.isRestored)
        kitchenRestorationStore.saveSettings()
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
        // The sheet also reports settings closed from here, which would forget what the kitchen opened since.
        guard viewModel?.openSettings != nil else {
            return
        }

        viewModel?.openSettings = nil
        kitchenRestorationStore.clear()
    }
}
