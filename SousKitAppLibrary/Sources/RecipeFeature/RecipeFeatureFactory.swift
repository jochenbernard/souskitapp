import RecipeLibrary

/// Builds ``RecipeFeature`` with what it reads.
public struct RecipeFeatureFactory: Sendable {
    private let recipeTextReader: RecipeTextReader

    /// Creates a factory.
    ///
    /// - Parameter recipeDirectory: The directory the recipes sit in.
    public init(recipeDirectory: RecipeDirectory) {
        self.recipeTextReader = RecipeTextReader(recipeDirectory: recipeDirectory)
    }

    /// Builds the feature.
    ///
    /// - Parameter recipeFile: The recipe to render.
    /// - Returns: The feature.
    public func makeRecipeFeature(recipeFile: RecipeFile) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let presenter = RecipeFeaturePresenter(
            recipeTextReader: recipeTextReader,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
