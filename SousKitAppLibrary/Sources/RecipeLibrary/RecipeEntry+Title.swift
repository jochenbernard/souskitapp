import SousKit

extension RecipeEntry {
    /// The title a recipe shows: the one its header gives, or the entry's name where it gives none.
    ///
    /// - Parameter recipe: The entry's recipe, already read.
    /// - Returns: The title.
    public func title(of recipe: Recipe) -> String {
        guard
            let title = recipe.metadata.title,
            !title.isEmpty
        else {
            return name
        }

        return title
    }
}
