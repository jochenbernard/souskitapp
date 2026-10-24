/// One recipe as a repository lists it, beside the names a search finds it by and the symbol picked for its card.
public struct ListedRecipe: Sendable, Hashable {
    /// The recipe.
    public let entry: RecipeEntry

    /// The names of the ingredients the recipe is made of, each once, or none where its contents have not been read.
    public let ingredientNames: [String]

    /// The symbol picked last for the recipe, or `nil` where none has been.
    public internal(set) var symbolPick: RecipeSymbolPick?

    /// Creates a listed recipe.
    ///
    /// - Parameters:
    ///   - entry: The recipe.
    ///   - ingredientNames: The names of the ingredients the recipe is made of, each once.
    ///   - symbolPick: The symbol picked last for the recipe, or `nil` where none has been.
    public init(
        entry: RecipeEntry,
        ingredientNames: [String],
        symbolPick: RecipeSymbolPick? = nil
    ) {
        self.entry = entry
        self.ingredientNames = ingredientNames
        self.symbolPick = symbolPick
    }
}
