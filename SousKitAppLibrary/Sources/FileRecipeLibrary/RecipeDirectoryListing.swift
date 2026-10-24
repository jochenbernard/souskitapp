import RecipeLibrary

/// What a recipe directory holds, down to the deepest directory inside it.
struct RecipeDirectoryListing: Sendable, Hashable {
    /// The recipe files, ordered by path.
    var recipeFiles: [RecipeFile]

    /// Where each directory read sits inside the recipe directory, the recipe directory itself as an empty path.
    var directoryPaths: Set<String>

    /// The pictures a recipe's header can name, by where each sits inside the recipe directory.
    var pictures: [String: RecipePicture] = [:]
}
