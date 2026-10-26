import CoreGraphics
import RecipeLibrary
import SousKit

/// Builds ``RecipeFeature`` with what it reads.
public struct RecipeFeatureFactory: Sendable {
    private let parser: SousParser
    private let preferredScaleStore: PreferredScaleStore
    private let recipeRepository: RecipeRepository

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - parser: What a scaled recipe's amounts are read back with.
    ///   - preferredScaleStore: Where the scale recipes open on is remembered.
    ///   - recipeRepository: The repository the recipes are read from.
    public init(
        parser: SousParser,
        preferredScaleStore: PreferredScaleStore,
        recipeRepository: RecipeRepository
    ) {
        self.parser = parser
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepository = recipeRepository
    }

    /// A factory building the same features from another repository.
    ///
    /// - Parameter recipeRepository: The repository the recipes are read from.
    /// - Returns: The factory.
    public func reading(_ recipeRepository: RecipeRepository) -> Self {
        Self(
            parser: parser,
            preferredScaleStore: preferredScaleStore,
            recipeRepository: recipeRepository
        )
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe to render.
    ///   - thumbnail: The recipe's picture as its card shows it, which the header shows until it reads its own, or
    ///     `nil` where the card shows none.
    ///   - restoration: How the screen was left, or `nil` for a screen just pushed.
    ///   - resumesCooking: Whether cooking opens again once the recipe is read.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    @MainActor
    public func makeRecipeFeature(
        recipeEntry: RecipeEntry,
        thumbnail: CGImage?,
        restoration: RecipeFeatureRestoration?,
        resumesCooking: Bool,
        handler: RecipeFeatureHandler
    ) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(
            recipeEntry: recipeEntry,
            folderPath: [recipeRepository.name] + recipeEntry.folderPath,
            placeholderRecipe: .placeholder(parser: parser),
            thumbnail: thumbnail
        )
        let presenter = RecipeFeaturePresenter(
            handler: handler,
            parser: parser,
            preferredScaleStore: preferredScaleStore,
            recipeRepository: recipeRepository,
            restoration: restoration,
            resumesCooking: resumesCooking,
            viewModel: viewModel
        )
        return RecipeFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
