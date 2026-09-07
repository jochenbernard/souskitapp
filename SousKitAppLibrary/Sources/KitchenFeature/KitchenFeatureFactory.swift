import RecipeFeature
import RecipeLibrary

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    /// Creates a factory.
    public init() {}

    /// Builds the feature.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from.
    /// - Returns: The feature.
    public func makeKitchenFeature(recipeDirectory: RecipeDirectory) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeDirectory: recipeDirectory)
        let presenter = KitchenFeaturePresenter(
            recipeDirectoryMonitor: RecipeDirectoryMonitor(recipeDirectory: recipeDirectory),
            recipeFeatureFactory: RecipeFeatureFactory(recipeDirectory: recipeDirectory),
            viewModel: viewModel
        )
        return KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
