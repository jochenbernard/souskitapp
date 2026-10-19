/// Picks the symbol a recipe's card shows where it has no picture.
public protocol RecipeSymbolPicker: Sendable {
    /// The version of how symbols are picked, which changes whenever a symbol picked before may no longer be the one
    /// picked now.
    var promptVersion: Int { get }

    /// Whether symbols can be picked, yielded once now and again after every change to it.
    ///
    /// Cancelling the task iterating the stream ends it.
    ///
    /// - Returns: The stream.
    func availabilityUpdates() -> AsyncStream<Bool>

    /// Picks the symbol for a recipe, the same one each time for the same input.
    ///
    /// - Parameter input: What the symbol is picked from.
    /// - Returns: The name of the SF Symbol.
    /// - Throws: Whatever picking the symbol throws.
    func symbol(for input: RecipeSymbolInput) async throws -> String
}
