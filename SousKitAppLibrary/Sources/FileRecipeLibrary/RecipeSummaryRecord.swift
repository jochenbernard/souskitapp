import Foundation
import RecipeLibrary
import SousKit

/// A recipe's summary as the cache keeps it, beside the date of the contents it was read from.
struct RecipeSummaryRecord: Sendable, Hashable, Codable {
    /// When the contents the summary was read from last changed.
    let modificationDate: Date

    /// The recipe's header as Sous source text, since `Metadata` has no coding of its own.
    let header: String

    /// The names of the ingredients the recipe is made of, in the order it first calls for them, each once.
    let ingredientNames: [String]

    /// The symbol picked last for the recipe, or `nil` where none has been.
    var symbolPick: RecipeSymbolPick?

    /// Creates the record of a recipe read.
    ///
    /// - Parameters:
    ///   - recipe: The recipe.
    ///   - modificationDate: When the contents it was read from last changed.
    ///   - symbolPick: The symbol picked last for the recipe, whatever contents it was picked from.
    init(
        recipe: Recipe,
        modificationDate: Date,
        symbolPick: RecipeSymbolPick? = nil
    ) {
        var headerOnly = recipe
        headerOnly.groups = []

        self.modificationDate = modificationDate
        self.header = headerOnly.serialized()
        self.ingredientNames = recipe.foodIngredientNames
        self.symbolPick = symbolPick
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
