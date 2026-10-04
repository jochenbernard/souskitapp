import Foundation

/// The recipe repository the user connected, remembered across launches.
public protocol RecipeRepositoryStore: Sendable {
    /// Builds the repository the user connected.
    ///
    /// Every call builds a new repository, so a caller keeps the one it builds.
    ///
    /// - Returns: The repository, or `nil` before the user has connected one.
    @MainActor
    func makeRecipeRepository() -> RecipeRepository?

    /// Records the directory at a URL as the one recipes are read from.
    ///
    /// - Parameter url: The directory the user picked.
    /// - Returns: The repository reading the directory.
    /// - Throws: Whatever remembering `url` throws.
    @MainActor
    func connectRecipeDirectory(at url: URL) throws -> RecipeRepository

    /// Forgets the repository, leaving the app nowhere to read recipes from.
    @MainActor
    func clear()
}
