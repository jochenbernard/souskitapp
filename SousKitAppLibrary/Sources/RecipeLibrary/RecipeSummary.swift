import SousKit

/// What a list knows of a recipe without reading it.
public struct RecipeSummary: Sendable, Hashable {
    /// The recipe's header.
    public let metadata: Metadata

    /// How long the recipe takes, or `nil` where its header does not say.
    public let totalTime: TotalTime?

    /// The symbol picked last for the recipe, or `nil` where none has been.
    public internal(set) var symbolPick: RecipeSymbolPick?

    /// Creates a summary.
    ///
    /// - Parameters:
    ///   - metadata: The recipe's header.
    ///   - parser: What the header's times are read with.
    ///   - symbolPick: The symbol picked last for the recipe, or `nil` where none has been.
    public init(
        metadata: Metadata,
        parser: SousParser,
        symbolPick: RecipeSymbolPick? = nil
    ) {
        self.metadata = metadata
        self.totalTime = TotalTime(metadata: metadata, parser: parser)
        self.symbolPick = symbolPick
    }

    /// Creates the summary of a recipe already read.
    ///
    /// - Parameters:
    ///   - recipe: The recipe.
    ///   - parser: What the header's times are read with.
    public init(recipe: Recipe, parser: SousParser) {
        self.init(metadata: recipe.metadata, parser: parser)
    }
}
