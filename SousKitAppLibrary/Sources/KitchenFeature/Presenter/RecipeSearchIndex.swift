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

    private var listedRecipes: [ListedRecipe] = []
    // Built by the first search after a listing, since a listing arrives for every file landing from iCloud.
    // swiftlint:disable:next discouraged_optional_collection
    private var indexedRecipes: [IndexedRecipe]?

    /// Replaces the recipes searched with those listed now.
    ///
    /// - Parameter listedRecipes: The recipes, in every folder.
    func update(_ listedRecipes: [ListedRecipe]) {
        self.listedRecipes = listedRecipes
        indexedRecipes = nil
    }

    /// The recipes in a folder and the folders below it matching every word searched for, those matching by title
    /// first, then by tag, then by ingredient, each by title.
    ///
    /// - Parameters:
    ///   - queryWords: The words searched for, from ``RecipeSearchTerms/words(of:)``.
    ///   - folderPath: The names of the folders leading down to the folder searched, or none for the top.
    /// - Returns: The recipes, or none where no word is searched for.
    func results(matching queryWords: [String], below folderPath: [String]) -> [RecipeEntry] {
        let matches = indexed()
            .filter({ $0.entry.folderPath.starts(with: folderPath) })
            .compactMap { recipe in
                recipe.terms.match(queryWords).map({ (match: $0, entry: recipe.entry) })
            }

        return RecipeSearchMatch.allCases.flatMap { match in
            matches.filter({ $0.match == match }).map(\.entry)
        }
    }

    /// The recipes listed with their terms, in the order the kitchen lists recipes.
    private func indexed() -> [IndexedRecipe] {
        if let indexedRecipes {
            return indexedRecipes
        }

        let builtRecipes = listedRecipes
            .sorted(by: { KitchenFolderTree.isOrderedBefore($0.entry, $1.entry) })
            .map({ IndexedRecipe(entry: $0.entry, terms: RecipeSearchTerms($0)) })
        indexedRecipes = builtRecipes

        return builtRecipes
    }
}
