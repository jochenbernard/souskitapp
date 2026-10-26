import Foundation

/// The order a listing's folders and recipes are shown in, the recipes a folder is shown by, and the pictures shown
/// first, so what is read ahead of a listing is what it shows.
public enum RecipeListingOrder {
    /// The folders and recipes directly in one folder, each in the order listed.
    private struct Level {
        let folders: [Self]
        let ownEntries: [RecipeEntry]

        /// The recipes the folder is shown by: its own first, then those its folders are shown by.
        var folderRecipes: [RecipeEntry] {
            let limit = RecipeListingOrder.folderRecipeLimit

            return Array((ownEntries.prefix(limit) + folders.lazy.flatMap(\.folderRecipes)).prefix(limit))
        }

        /// The recipes each card listed in the folder is shown by: a folder's, then each recipe's own, in the order
        /// the cards are listed.
        var cardRecipes: [[RecipeEntry]] {
            folders.map(\.folderRecipes) + ownEntries.map({ [$0] })
        }

        init(_ recipeEntries: [RecipeEntry], depth: Int) {
            var directEntries: [RecipeEntry] = []
            var innerEntries: [String: [RecipeEntry]] = [:]

            for recipeEntry in recipeEntries {
                if recipeEntry.folderPath.count > depth {
                    innerEntries[recipeEntry.folderPath[depth], default: []].append(recipeEntry)
                } else {
                    directEntries.append(recipeEntry)
                }
            }

            self.folders = innerEntries.keys.sorted(by: RecipeListingOrder.isOrderedBefore).map { name in
                Level(innerEntries[name] ?? [], depth: depth + 1)
            }
            self.ownEntries = directEntries.sorted(by: RecipeListingOrder.isOrderedBefore)
        }
    }

    /// The most recipes a folder is shown by.
    public static let folderRecipeLimit = 4

    // About the first two screens of an iPhone, and what is read ahead before a screen is measured.
    private static let minimumFirstPictureCount = 24

    /// Whether one folder is listed before another: by name, then by the name's exact characters, so names differing
    /// only in case keep one order.
    ///
    /// - Parameters:
    ///   - lhs: One folder's name.
    ///   - rhs: The other folder's name.
    /// - Returns: Whether `lhs` is listed first.
    public static func isOrderedBefore(_ lhs: String, _ rhs: String) -> Bool {
        switch lhs.localizedStandardCompare(rhs) {
        case .orderedAscending:
            true

        case .orderedDescending:
            false

        case .orderedSame:
            lhs < rhs
        }
    }

    /// Whether one recipe is listed before another: by its title, then by what the repository finds it by, so recipes
    /// sharing a title keep one order.
    ///
    /// - Parameters:
    ///   - lhs: One recipe.
    ///   - rhs: The other recipe.
    /// - Returns: Whether `lhs` is listed first.
    public static func isOrderedBefore(_ lhs: RecipeEntry, _ rhs: RecipeEntry) -> Bool {
        switch lhs.title.localizedStandardCompare(rhs.title) {
        case .orderedAscending:
            true

        case .orderedDescending:
            false

        case .orderedSame:
            lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
        }
    }

    /// The pictures shown first at the top of a listing: those of the recipes each folder there is shown by, then
    /// those of the recipes directly there: the pictures of the cards filling a screen, and at least 24.
    ///
    /// - Parameters:
    ///   - recipeEntries: The recipes, in any order.
    ///   - cardCount: How many cards fill the screen the listing is shown on, or 0 where it is not measured yet.
    /// - Returns: The pictures, the first shown first.
    public static func firstPictures(of recipeEntries: [RecipeEntry], cardCount: Int) -> [RecipePicture] {
        let cardRecipes = Level(recipeEntries, depth: 0).cardRecipes
        let screenPictureCount = cardRecipes.prefix(cardCount).joined().count(where: { $0.picture != nil })

        return Array(
            cardRecipes.joined().lazy.compactMap(\.picture).prefix(max(screenPictureCount, minimumFirstPictureCount))
        )
    }
}
