import RecipeLibrary

/// Builds ``RecipeFeature`` with what it reads.
public struct RecipeFeatureFactory: Sendable {
    private let recipeRepository: RecipeRepository

    /// Creates a factory.
    ///
    /// - Parameter recipeRepository: The repository the recipes are read from.
    public init(recipeRepository: RecipeRepository) {
        self.recipeRepository = recipeRepository
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe to render.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    public func makeRecipeFeature(
        recipeEntry: RecipeEntry,
        handler: RecipeFeatureHandler
    ) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(recipeEntry: recipeEntry)
        let presenter = RecipeFeaturePresenter(
            handler: handler,
            recipeRepository: recipeRepository,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
