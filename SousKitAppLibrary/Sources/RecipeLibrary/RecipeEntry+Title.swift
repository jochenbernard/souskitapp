import SousKit

extension RecipeEntry {
    /// The title the recipe shows before it is read: its summary's, or the entry's name where that gives none.
    public var title: String {
        summary.map({ title(in: $0.metadata) }) ?? name
    }

    /// The title a recipe shows: the one its header gives, or the entry's name where it gives none.
    ///
    /// - Parameter recipe: The entry's recipe, already read.
    /// - Returns: The title.
    public func title(of recipe: Recipe) -> String {
        title(in: recipe.metadata)
    }

    private func title(in metadata: Metadata) -> String {
        guard
            let headerTitle = metadata.title,
            !headerTitle.isEmpty
        else {
            return name
        }

        return headerTitle
    }
}
