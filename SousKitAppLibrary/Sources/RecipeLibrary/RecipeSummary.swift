import SousKit

/// What a list knows of a recipe without reading it.
public struct RecipeSummary: Sendable, Hashable {
    /// The recipe's header.
    public let metadata: Metadata

    /// How long the recipe takes, or `nil` where its header does not say.
    public let totalTime: TotalTime?

    /// Creates a summary.
    ///
    /// - Parameters:
    ///   - metadata: The recipe's header.
    ///   - parser: What the header's times are read with.
    public init(metadata: Metadata, parser: SousParser) {
        self.metadata = metadata
        self.totalTime = TotalTime(metadata: metadata, parser: parser)
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
