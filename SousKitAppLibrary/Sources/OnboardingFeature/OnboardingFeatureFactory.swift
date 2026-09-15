import RecipeLibrary

/// Builds ``OnboardingFeature`` with what it reads and writes.
public struct OnboardingFeatureFactory: Sendable {
    private let recipeRepositoryStore: RecipeRepositoryStore

    /// Creates a factory.
    ///
    /// - Parameter recipeRepositoryStore: Where the picked directory is recorded.
    public init(recipeRepositoryStore: RecipeRepositoryStore) {
        self.recipeRepositoryStore = recipeRepositoryStore
    }

    /// Builds the feature.
    ///
    /// - Parameter handler: What the feature reports its result to.
    /// - Returns: The feature.
    public func makeOnboardingFeature(handler: OnboardingFeatureHandler) -> OnboardingFeature {
        let viewModel = OnboardingFeatureViewModel()
        let presenter = OnboardingFeaturePresenter(
            handler: handler,
            recipeRepositoryStore: recipeRepositoryStore,
            viewModel: viewModel
        )
        return OnboardingFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
