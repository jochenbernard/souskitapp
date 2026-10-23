import Foundation
import RecipeLibrary

/// Builds the folders the kitchen lists out of the recipes a repository yields, each carrying the path of its folder.
enum KitchenFolderTree {
    /// The most recipes a folder's picture stacks.
    static let stackedCardLimit = 4

    /// The folder at a path, holding the folders below it that hold recipes and the recipes directly in it.
    ///
    /// - Parameters:
    ///   - path: The names of the folders leading down to it, or none for the top of the repository.
    ///   - recipeEntries: The recipes somewhere below it, each with a folder path starting with `path`.
    /// - Returns: The folder.
    static func folder(at path: [String], holding recipeEntries: [RecipeEntry]) -> KitchenFolder {
        var ownEntries: [RecipeEntry] = []
        var innerEntries: [String: [RecipeEntry]] = [:]

        for recipeEntry in recipeEntries {
            if recipeEntry.folderPath.count > path.count {
                innerEntries[recipeEntry.folderPath[path.count], default: []].append(recipeEntry)
            } else {
                ownEntries.append(recipeEntry)
            }
        }

        let folders = innerEntries.keys.sorted(by: isOrderedBefore).map { name in
            folder(at: path + [name], holding: innerEntries[name] ?? [])
        }
        let cards = ownEntries.sorted(by: isOrderedBefore).map(KitchenFeaturePresenter.card(for:))
        // Its own recipes first, then those in the folders inside it.
        let stackedCards = cards.prefix(stackedCardLimit) + folders.lazy.flatMap(\.stackedCards)

        return KitchenFolder(
            path: path,
            folders: folders,
            cards: cards,
            recipeCount: recipeEntries.count,
            stackedCards: Array(stackedCards.prefix(stackedCardLimit))
        )
    }

    /// Whether one folder is listed before another: by name, then by the name's exact characters, so names differing
    /// only in case keep one order.
    private static func isOrderedBefore(_ lhs: String, _ rhs: String) -> Bool {
        switch lhs.localizedStandardCompare(rhs) {
        case .orderedAscending:
            true

        case .orderedDescending:
            false

        case .orderedSame:
            lhs < rhs
        }
    }

    /// Whether one recipe is listed before another: by the title its card shows, then by what the repository finds it
    /// by, so recipes sharing a title keep one order.
    private static func isOrderedBefore(_ lhs: RecipeEntry, _ rhs: RecipeEntry) -> Bool {
        switch lhs.title.localizedStandardCompare(rhs.title) {
        case .orderedAscending:
            true

        case .orderedDescending:
            false

        case .orderedSame:
            lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
        }
    }
}
