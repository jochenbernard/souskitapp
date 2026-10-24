/// The symbol picked for a recipe, beside what identifies the input and the prompt it was picked with.
public struct RecipeSymbolPick: Sendable, Hashable, Codable {
    /// The name of the SF Symbol.
    public let symbol: String

    private let inputDigest: String
    private let promptVersion: Int

    /// Creates a pick.
    ///
    /// - Parameters:
    ///   - symbol: The name of the SF Symbol.
    ///   - input: What the symbol was picked from.
    ///   - promptVersion: The version of how the symbol was picked.
    public init(
        symbol: String,
        input: RecipeSymbolInput,
        promptVersion: Int
    ) {
        self.symbol = symbol
        self.inputDigest = input.digest
        self.promptVersion = promptVersion
    }

    /// Whether the symbol was picked from an input, with a version of how symbols are picked.
    ///
    /// - Parameters:
    ///   - input: The input.
    ///   - promptVersion: The version of how symbols are picked.
    /// - Returns: Whether picking again would ask for the same symbol.
    public func isCurrent(for input: RecipeSymbolInput, promptVersion: Int) -> Bool {
        self.promptVersion == promptVersion && inputDigest == input.digest
    }
}
