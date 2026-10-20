import Foundation
import RecipeLibrary
import SousKit

/// A recipe's summary as the cache keeps it, beside the date of the contents it was read from.
struct RecipeSummaryRecord: Sendable, Hashable, Codable {
    /// When the contents the summary was read from last changed.
    let modificationDate: Date

    /// The recipe's header as Sous source text, since `Metadata` has no coding of its own.
    let header: String

    /// The names of the recipe's ingredients, in the order the recipe first calls for them, each once.
    let ingredientNames: [String]

    /// Creates the record of a recipe read.
    ///
    /// - Parameters:
    ///   - recipe: The recipe.
    ///   - modificationDate: When the contents it was read from last changed.
    init(recipe: Recipe, modificationDate: Date) {
        var headerOnly = recipe
        headerOnly.groups = []

        self.modificationDate = modificationDate
        self.header = headerOnly.serialized()
        var seen: Set<String> = []
        self.ingredientNames = recipe.ingredients.map(\.name).filter({ seen.insert($0).inserted })
    }

    /// Whether the summary still holds for a file as it is listed now.
    ///
    /// An outdated file has changed whatever its date says, and a file telling no date counts as changed.
    ///
    /// - Parameter file: The file the summary was read from.
    /// - Returns: Whether the file is unchanged since.
    func isCurrent(for file: RecipeFile) -> Bool {
        guard !file.isOutdated, let fileModificationDate = file.modificationDate else {
            return false
        }

        return fileModificationDate == modificationDate
    }

    /// The summary the record keeps.
    ///
    /// - Parameter parser: What the header is read back with.
    /// - Returns: The summary.
    func summary(parsedWith parser: SousParser) -> RecipeSummary {
        RecipeSummary(metadata: parser.parseRecipe(header).value.metadata, parser: parser)
    }
}
