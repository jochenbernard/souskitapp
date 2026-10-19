import SousKit

/// What a list knows of a recipe without reading it.
public struct RecipeSummary: Sendable, Hashable {
    /// The recipe's header.
    public let metadata: Metadata

    /// Creates a summary.
    ///
    /// - Parameter metadata: The recipe's header.
    public init(metadata: Metadata) {
        self.metadata = metadata
    }

    /// Creates the summary of a recipe already read.
    ///
    /// - Parameter recipe: The recipe.
    public init(recipe: Recipe) {
        self.init(metadata: recipe.metadata)
    }
}
