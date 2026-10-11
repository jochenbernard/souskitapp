import CookingFeature
import FileRecipeLibrary
import Foundation
import KitchenFeature
import MockRecipeLibrary
import OnboardingFeature
import RecipeLibrary
import SettingsFeature
import SousKit

/// Builds ``AppFeature`` and everything under it.
struct AppFeatureFactory {
    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let preferredScaleStore: UserDefaultsPreferredScaleStore
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore
    private let restorationStore: AppRestorationStore
    private let settingsFeatureFactory: SettingsFeatureFactory
    private let timerScheduler: TimerScheduler

    @MainActor
    init() {
        // One parser for the whole app, handed down to everything that reads Sous.
        let parser = SousParser()
        let store = FileRecipeRepositoryStore(parser: parser)
        let scaleStore = UserDefaultsPreferredScaleStore()
        // One scheduler for the whole app, so what decides a cold start sees the timers cooking runs.
        let scheduler = AlarmTimerScheduler()
        self.kitchenFeatureFactory = KitchenFeatureFactory(
            parser: parser,
            preferredScaleStore: scaleStore,
            timerScheduler: scheduler
        )
        self.mockRecipeRepository = MockRecipeRepository(parser: parser)
        self.onboardingFeatureFactory = OnboardingFeatureFactory(recipeRepositoryStore: store)
        self.preferredScaleStore = scaleStore
        self.recipeRepositoryKindStore = RecipeRepositoryKindStore()
        self.recipeRepositoryStore = store
        self.restorationStore = AppRestorationStore()
        self.settingsFeatureFactory = SettingsFeatureFactory(
            appVersion: AppVersion(bundle: .main),
            preferredScaleStore: scaleStore,
            recipeRepositoryStore: store
        )
        self.timerScheduler = scheduler
    }

    /// Builds the feature, opening on whichever screen the remembered repository calls for, with what the app had open
    /// when it last ran.
    ///
    /// - Returns: The feature.
    @MainActor
    func makeAppFeature() -> AppFeature {
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: kitchenFeatureFactory,
            mockRecipeRepository: mockRecipeRepository,
            onboardingFeatureFactory: onboardingFeatureFactory,
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore,
            restorationSettleTime: .seconds(5),
            restorationStore: restorationStore,
            settingsFeatureFactory: settingsFeatureFactory,
            timerScheduler: timerScheduler
        )

        return AppFeature(
            presenter: presenter,
            viewModel: presenter.makeViewModel()
        )
    }
}
