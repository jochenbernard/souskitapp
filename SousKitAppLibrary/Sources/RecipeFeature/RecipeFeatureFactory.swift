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
    /// - Parameters:
    ///   - recipeFile: The recipe to render.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    public func makeRecipeFeature(
        recipeFile: RecipeFile,
        handler: RecipeFeatureHandler
    ) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let presenter = RecipeFeaturePresenter(
            handler: handler,
            recipeReader: recipeReader,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
