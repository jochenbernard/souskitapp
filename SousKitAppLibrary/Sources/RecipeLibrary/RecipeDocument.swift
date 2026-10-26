import Foundation

/// A recipe file handed to the app from outside it, such as one opened from the Files app, with the repository reading
/// that file alone.
public struct RecipeDocument: Sendable {
    /// Where the file sits.
    public let url: URL

    /// The recipe as the file's own repository lists it.
    public let entry: RecipeEntry

    /// The repository reading the file where it sits, which lists it alone.
    public let recipeRepository: RecipeRepository

    /// Creates a document.
    ///
    /// - Parameters:
    ///   - url: Where the file sits.
    ///   - entry: The recipe as `recipeRepository` lists it.
    ///   - recipeRepository: The repository reading the file where it sits.
    public init(
        url: URL,
        entry: RecipeEntry,
        recipeRepository: RecipeRepository
    ) {
        self.url = url
        self.entry = entry
        self.recipeRepository = recipeRepository
    }
}
