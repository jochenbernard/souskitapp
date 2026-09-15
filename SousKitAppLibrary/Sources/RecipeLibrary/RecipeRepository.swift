import SousKit

/// The user's recipes, listed and read wherever they are kept.
public protocol RecipeRepository: Sendable {
    /// What the user knows the recipes by, such as the name of the folder holding them.
    var name: String { get }

    /// The recipes, yielded once now and again after every change to them.
    ///
    /// Cancelling the task iterating the stream ends it. One stream runs at a time; a second call ends the first.
    ///
    /// - Returns: The stream.
    func recipeEntries() async -> AsyncStream<Result<[RecipeEntry], Error>>

    /// Reads the recipes again, for the changes that reach the app no other way: a sync that landed while the app
    /// was in the background.
    ///
    /// The recipes read arrive on the stream from ``recipeEntries()``, not by the time the call returns.
    func refresh() async

    /// Reads a recipe and parses it.
    ///
    /// Parsing always lands, so a recipe comes back whatever it holds, with what the parser found wrong beside it.
    /// Only reading the recipe throws.
    ///
    /// - Parameter entry: The recipe to read.
    /// - Returns: The recipe, and the diagnostics from parsing it.
    /// - Throws: Whatever reading the recipe throws.
    func readRecipe(of entry: RecipeEntry) async throws -> Parsed<Recipe>
}
