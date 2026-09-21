import CookingFeature
import RecipeFeature
import RecipeLibrary
import SousKit

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    private let parser: SousParser

    /// Creates a factory.
    ///
    /// - Parameter parser: What the kitchen reads Sous with.
    public init(parser: SousParser) {
        self.parser = parser
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeRepository: The repository recipes are read from.
    ///   - handler: What the feature reports out of the kitchen to.
    /// - Returns: The feature.
    public func makeKitchenFeature(
        recipeRepository: RecipeRepository,
        handler: KitchenFeatureHandler
    ) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: recipeRepository.name)
        let presenter = KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(idleTimer: ApplicationIdleTimer()),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            viewModel: viewModel
        )
        return KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
