import RecipeLibrary

/// Builds ``OnboardingFeature`` with what it reads and writes.
public struct OnboardingFeatureFactory: Sendable {
    private let recipeDirectoryStore: RecipeDirectoryStore

    /// Creates a factory.
    ///
    /// - Parameter recipeDirectoryStore: Where the picked directory is recorded.
    public init(recipeDirectoryStore: RecipeDirectoryStore) {
        self.recipeDirectoryStore = recipeDirectoryStore
    }

    /// Builds the feature.
    ///
    /// - Parameter handler: What the feature reports its result to.
    /// - Returns: The feature.
    public func makeOnboardingFeature(handler: OnboardingFeatureHandler) -> OnboardingFeature {
        let viewModel = OnboardingFeatureViewModel()
        let presenter = OnboardingFeaturePresenter(
            handler: handler,
            recipeDirectoryStore: recipeDirectoryStore,
            viewModel: viewModel
        )
        return OnboardingFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
