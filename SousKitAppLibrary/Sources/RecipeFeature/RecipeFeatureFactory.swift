import RecipeLibrary

/// Builds ``RecipeFeature`` with what it reads.
public struct RecipeFeatureFactory: Sendable {
    private let recipeReader: RecipeReader

    /// Creates a factory.
    ///
    /// - Parameter recipeDirectory: The directory the recipes sit in.
    public init(recipeDirectory: RecipeDirectory) {
        self.recipeReader = RecipeReader(recipeDirectory: recipeDirectory)
    }

    /// Builds the feature.
    ///
    /// - Parameter recipeFile: The recipe to render.
    /// - Returns: The feature.
    public func makeRecipeFeature(recipeFile: RecipeFile) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let presenter = RecipeFeaturePresenter(
            recipeReader: recipeReader,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
