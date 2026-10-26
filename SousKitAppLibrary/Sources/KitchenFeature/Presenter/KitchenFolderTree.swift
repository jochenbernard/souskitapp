import RecipeLibrary

/// Builds the folders the kitchen lists out of the recipes a repository yields, each carrying the path of its folder.
enum KitchenFolderTree {
    /// The folder at a path, holding the folders below it that hold recipes and the recipes directly in it.
    ///
    /// - Parameters:
    ///   - path: The names of the folders leading down to it, or none for the top of the repository.
    ///   - recipeEntries: The recipes somewhere below it, each with a folder path starting with `path`.
    ///   - isListingRead: Whether any recipe listed has been read, so the pictures the recipes name are known.
    /// - Returns: The folder.
    static func folder(
        at path: [String],
        holding recipeEntries: [RecipeEntry],
        isListingRead: Bool = true
    ) -> KitchenFolder {
        var ownEntries: [RecipeEntry] = []
        var innerEntries: [String: [RecipeEntry]] = [:]

        for recipeEntry in recipeEntries {
            if recipeEntry.folderPath.count > path.count {
                innerEntries[recipeEntry.folderPath[path.count], default: []].append(recipeEntry)
            } else {
                ownEntries.append(recipeEntry)
            }
        }

        let folders = innerEntries.keys.sorted(by: RecipeListingOrder.isOrderedBefore).map { name in
            folder(
                at: path + [name],
                holding: innerEntries[name] ?? [],
                isListingRead: isListingRead
            )
        }
        let cards = ownEntries.sorted(by: RecipeListingOrder.isOrderedBefore).map { recipeEntry in
            KitchenRecipeCard(recipeEntry: recipeEntry, isPictureKnown: isListingRead)
        }
        // Its own recipes first, then those in the folders inside it.
        let stackedCards = cards.prefix(RecipeListingOrder.folderRecipeLimit) + folders.lazy.flatMap(\.stackedCards)

        return KitchenFolder(
            path: path,
            folders: folders,
            cards: cards,
            recipeCount: recipeEntries.count,
            stackedCards: Array(stackedCards.prefix(RecipeListingOrder.folderRecipeLimit))
        )
    }
}
