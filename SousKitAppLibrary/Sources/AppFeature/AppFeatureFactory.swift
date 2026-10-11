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
    private let kitchenRestorationStore: KitchenRestorationStore
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let preferredScaleStore: UserDefaultsPreferredScaleStore
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore
    private let settingsFeatureFactory: SettingsFeatureFactory

    @MainActor
    init() {
        // One parser for the whole app, handed down to everything that reads Sous.
        let parser = SousParser()
        let store = FileRecipeRepositoryStore(parser: parser)
        let restorationStore = KitchenRestorationStore()
        let scaleStore = UserDefaultsPreferredScaleStore()
        self.kitchenFeatureFactory = KitchenFeatureFactory(
            parser: parser,
            preferredScaleStore: scaleStore,
            restorationStore: restorationStore
        )
        self.kitchenRestorationStore = restorationStore
        self.mockRecipeRepository = MockRecipeRepository(parser: parser)
        self.onboardingFeatureFactory = OnboardingFeatureFactory(recipeRepositoryStore: store)
        self.preferredScaleStore = scaleStore
        self.recipeRepositoryKindStore = RecipeRepositoryKindStore()
        self.recipeRepositoryStore = store
        self.settingsFeatureFactory = SettingsFeatureFactory(
            appVersion: AppVersion(bundle: .main),
            preferredScaleStore: scaleStore,
            recipeRepositoryStore: store
        )
    }

    /// Builds the feature, opening on whichever screen the remembered repository calls for.
    ///
    /// - Returns: The feature.
    @MainActor
    func makeAppFeature() -> AppFeature {
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: kitchenFeatureFactory,
            kitchenRestorationStore: kitchenRestorationStore,
            mockRecipeRepository: mockRecipeRepository,
            onboardingFeatureFactory: onboardingFeatureFactory,
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore,
            settingsFeatureFactory: settingsFeatureFactory
        )
        let viewModel = AppFeatureViewModel(screen: presenter.makeScreen())
        presenter.viewModel = viewModel

        return AppFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
