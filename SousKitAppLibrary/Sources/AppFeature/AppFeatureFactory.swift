import FileRecipeLibrary
import KitchenFeature
import MockRecipeLibrary
import OnboardingFeature
import RecipeLibrary
import SousKit

/// Builds ``AppFeature`` and everything under it.
struct AppFeatureFactory {
    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let kitchenRestorationStore: KitchenRestorationStore
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore

    @MainActor
    init() {
        // One parser for the whole app, handed down to everything that reads Sous.
        let parser = SousParser()
        let store = FileRecipeRepositoryStore(parser: parser)
        let restorationStore = KitchenRestorationStore()
        self.kitchenFeatureFactory = KitchenFeatureFactory(
            parser: parser,
            restorationStore: restorationStore
        )
        self.kitchenRestorationStore = restorationStore
        self.mockRecipeRepository = MockRecipeRepository(parser: parser)
        self.onboardingFeatureFactory = OnboardingFeatureFactory(recipeRepositoryStore: store)
        self.recipeRepositoryKindStore = RecipeRepositoryKindStore()
        self.recipeRepositoryStore = store
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
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore
        )
        let viewModel = AppFeatureViewModel(screen: presenter.makeScreen())
        presenter.viewModel = viewModel

        return AppFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
