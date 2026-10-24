import Observation
import RecipeLibrary

/// The symbols the kitchen's cards show where they show no picture, each as it was picked last.
///
/// A view reading one recipe's symbol is redrawn when that symbol changes, not when another does.
@MainActor
final class KitchenSymbols {
    @Observable
    @MainActor
    final class Slot {
        var symbol: String?
    }

    // For a recipe no symbol has been picked for, such as where Apple Intelligence is unavailable.
    private static let unpickedSymbol = "fork.knife"

    // By recipe id.
    private var slots: [String: Slot] = [:]

    nonisolated init() {}

    /// The symbol a recipe's card shows.
    ///
    /// - Parameter recipeID: The recipe's id.
    /// - Returns: The symbol picked last for the recipe, or one for every recipe none has been picked for.
    subscript(recipeID: String) -> String {
        slot(for: recipeID).symbol ?? Self.unpickedSymbol
    }

    /// Shows each recipe's symbol as it is listed now.
    ///
    /// - Parameter listedRecipes: The recipes.
    func show(_ listedRecipes: [ListedRecipe]) {
        for listedRecipe in listedRecipes {
            let slot = slot(for: listedRecipe.entry.id)
            let symbol = listedRecipe.symbolPick?.symbol

            // Every listing names every recipe's symbol, and only one that changed redraws its card.
            if slot.symbol != symbol {
                slot.symbol = symbol
            }
        }
    }

    // A slot read before its recipe's symbol is shown is the one the symbol lands in.
    private func slot(for recipeID: String) -> Slot {
        if let slot = slots[recipeID] {
            return slot
        }

        let slot = Slot()
        slots[recipeID] = slot

        return slot
    }
}
