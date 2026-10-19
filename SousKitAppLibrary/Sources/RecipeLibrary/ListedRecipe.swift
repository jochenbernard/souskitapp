/// One recipe as a repository lists it, beside the names a search finds it by.
public struct ListedRecipe: Sendable, Hashable {
    /// The recipe.
    public let entry: RecipeEntry

    /// The names of the ingredients the recipe is made of, each once, or none where its contents have not been read.
    public let ingredientNames: [String]

    /// Creates a listed recipe.
    ///
    /// - Parameters:
    ///   - entry: The recipe.
    ///   - ingredientNames: The names of the ingredients the recipe is made of, each once.
    public init(entry: RecipeEntry, ingredientNames: [String] = []) {
        self.entry = entry
        self.ingredientNames = ingredientNames
    }
}
