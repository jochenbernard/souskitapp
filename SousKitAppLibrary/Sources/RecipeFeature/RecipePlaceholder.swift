import DesignSystem

/// What stands in for a recipe's picture where it has none, as its card in the kitchen shows it.
public struct RecipePlaceholder: Sendable, Hashable {
    /// The name of the SF Symbol standing in for the recipe.
    public let symbol: String

    /// The recipe's color.
    public let color: SousPlaceholderColor

    /// Creates a placeholder.
    ///
    /// - Parameters:
    ///   - symbol: The name of the SF Symbol standing in for the recipe.
    ///   - color: The recipe's color.
    public init(
        symbol: String,
        color: SousPlaceholderColor
    ) {
        self.symbol = symbol
        self.color = color
    }
}
