import RecipeLibrary

/// Builds ``KitchenFeature``.
public struct KitchenFeatureFactory: Sendable {
    /// Creates a factory.
    public init() {}

    /// Builds the feature.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from.
    /// - Returns: The feature.
    public func makeKitchenFeature(recipeDirectory: RecipeDirectory) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeDirectory: recipeDirectory)
        return KitchenFeature(viewModel: viewModel)
    }
}
