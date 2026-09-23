import RecipeLibrary
import SousKit

/// Builds ``RecipeFeature`` with what it reads.
public struct RecipeFeatureFactory: Sendable {
    private let parser: SousParser
    private let recipeRepository: RecipeRepository

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - parser: What a scaled recipe's amounts are read back with.
    ///   - recipeRepository: The repository the recipes are read from.
    public init(
        parser: SousParser,
        recipeRepository: RecipeRepository
    ) {
        self.parser = parser
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
            parser: parser,
            recipeRepository: recipeRepository,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
