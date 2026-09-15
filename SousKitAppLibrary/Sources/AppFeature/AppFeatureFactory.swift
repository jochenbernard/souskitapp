import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// Builds ``AppFeature`` and everything under it.
struct AppFeatureFactory {
    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeDirectoryStore: RecipeDirectoryStore

    init() {
        let store = RecipeDirectoryStore()
        self.kitchenFeatureFactory = KitchenFeatureFactory()
        self.onboardingFeatureFactory = OnboardingFeatureFactory(recipeDirectoryStore: store)
        self.recipeDirectoryStore = store
    }

    /// Builds the feature, opening on whichever screen the remembered directory calls for.
    ///
    /// - Returns: The feature.
    @MainActor
    func makeAppFeature() -> AppFeature {
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: kitchenFeatureFactory,
            onboardingFeatureFactory: onboardingFeatureFactory,
            recipeDirectoryStore: recipeDirectoryStore
        )
        let screen = presenter.makeScreen(recipeDirectory: recipeDirectoryStore.recipeDirectory)
        let viewModel = AppFeatureViewModel(screen: screen)
        presenter.viewModel = viewModel

        return AppFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
