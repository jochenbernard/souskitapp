import FileRecipeLibrary
import KitchenFeature
import OnboardingFeature
import RecipeLibrary
import SousKit

/// Builds ``AppFeature`` and everything under it.
struct AppFeatureFactory {
    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeRepositoryStore: RecipeRepositoryStore

    init() {
        // One parser for the whole app, handed down to everything that reads Sous.
        let parser = SousParser()
        let store = FileRecipeRepositoryStore(parser: parser)
        self.kitchenFeatureFactory = KitchenFeatureFactory(parser: parser)
        self.onboardingFeatureFactory = OnboardingFeatureFactory(recipeRepositoryStore: store)
        self.recipeRepositoryStore = store
    }

    /// Builds the feature, opening on whichever screen the connected repository calls for.
    ///
    /// - Returns: The feature.
    @MainActor
    func makeAppFeature() -> AppFeature {
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: kitchenFeatureFactory,
            onboardingFeatureFactory: onboardingFeatureFactory,
            recipeRepositoryStore: recipeRepositoryStore
        )
        let screen = presenter.makeScreen(recipeRepository: recipeRepositoryStore.makeRecipeRepository())
        let viewModel = AppFeatureViewModel(screen: screen)
        presenter.viewModel = viewModel

        return AppFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
