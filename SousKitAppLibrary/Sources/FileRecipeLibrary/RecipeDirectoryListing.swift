/// What a recipe directory holds, down to the deepest directory inside it.
struct RecipeDirectoryListing: Sendable, Hashable {
    /// The recipe files, ordered by path.
    var recipeFiles: [RecipeFile]

    /// Where each directory read sits inside the recipe directory, ordered, the recipe directory itself as an empty
    /// path.
    var directoryPaths: [String]
}
