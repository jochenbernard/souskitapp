import SousKit

/// What a list knows of a recipe without reading it: its header, and the ingredients it calls for.
public struct RecipeSummary: Sendable, Hashable {
    /// The recipe's header.
    public let metadata: Metadata

    /// The names of the ingredients, in the order the recipe first calls for them, each once.
    public let ingredientNames: [String]

    /// Creates a summary.
    ///
    /// - Parameters:
    ///   - metadata: The recipe's header.
    ///   - ingredientNames: The names of the ingredients, each once.
    public init(
        metadata: Metadata,
        ingredientNames: [String]
    ) {
        self.metadata = metadata
        self.ingredientNames = ingredientNames
    }

    /// Creates the summary of a recipe already read.
    ///
    /// - Parameter recipe: The recipe.
    public init(recipe: Recipe) {
        var seen: Set<String> = []

        self.init(
            metadata: recipe.metadata,
            ingredientNames: recipe.ingredients.map(\.name).filter({ seen.insert($0).inserted })
        )
    }
}
