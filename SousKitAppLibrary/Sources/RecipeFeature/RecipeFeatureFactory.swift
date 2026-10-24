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

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe to render.
    ///   - restoration: How the screen was left, or `nil` for a screen just pushed.
    ///   - resumesCooking: Whether cooking opens again once the recipe is read.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    @MainActor
    public func makeRecipeFeature(
        recipeEntry: RecipeEntry,
        restoration: RecipeFeatureRestoration?,
        resumesCooking: Bool,
        handler: RecipeFeatureHandler
    ) -> RecipeFeature {
        let viewModel = RecipeFeatureViewModel(
            recipeEntry: recipeEntry,
            folderPath: [recipeRepository.name] + recipeEntry.folderPath
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
