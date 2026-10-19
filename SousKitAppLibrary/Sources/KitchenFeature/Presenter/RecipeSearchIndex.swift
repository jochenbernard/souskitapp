import RecipeLibrary

/// The recipes a search runs over, kept from the repository's last listing so searching reads no recipe.
///
/// A class, so every copy of the presenter searches the same one.
@MainActor
final class RecipeSearchIndex {
    private struct IndexedRecipe {
        let entry: RecipeEntry
        let terms: RecipeSearchTerms
    }

    private var recipes: [IndexedRecipe] = []

    /// Replaces the recipes searched with those listed now.
    ///
    /// - Parameter listedRecipes: The recipes, in every folder.
    func update(_ listedRecipes: [ListedRecipe]) {
        recipes = listedRecipes.map { listedRecipe in
            IndexedRecipe(entry: listedRecipe.entry, terms: RecipeSearchTerms(listedRecipe))
        }
    }

    /// The recipes matching every word searched for, those matching by title first, then by tag, then by ingredient,
    /// each by title.
    ///
    /// - Parameter queryWords: The words searched for, from ``RecipeSearchTerms/words(of:)``.
    /// - Returns: The recipes, or none where no word is searched for.
    func results(matching queryWords: [String]) -> [RecipeEntry] {
        recipes
            .compactMap { recipe in
                recipe.terms.match(queryWords).map({ (match: $0, entry: recipe.entry) })
            }
            .sorted(by: { Self.isOrderedBefore($0, $1) })
            .map(\.entry)
    }

    private static func isOrderedBefore(
        _ lhs: (match: RecipeSearchMatch, entry: RecipeEntry),
        _ rhs: (match: RecipeSearchMatch, entry: RecipeEntry)
    ) -> Bool {
        guard lhs.match == rhs.match else {
            return lhs.match < rhs.match
        }

        return KitchenFolderTree.isOrderedBefore(lhs.entry, rhs.entry)
    }
}
