import CookingFeature
import RecipeFeature
import RecipeLibrary

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    /// Creates a factory.
    public init() {}

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory recipes are read from.
    ///   - handler: What the feature reports out of the kitchen to.
    /// - Returns: The feature.
    public func makeKitchenFeature(
        recipeDirectory: RecipeDirectory,
        handler: KitchenFeatureHandler
    ) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeDirectory: recipeDirectory)
        let presenter = KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(idleTimer: ApplicationIdleTimer()),
            handler: handler,
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
