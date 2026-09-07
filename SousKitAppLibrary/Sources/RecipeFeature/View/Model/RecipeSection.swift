import SwiftUI

/// A section of the recipe screen that opens and closes.
enum RecipeSection: Hashable {
    case ingredients
    case cookware
    case steps

    /// The sections a recipe opens on, which leaves the cookware closed.
    static let openByDefault: Set<RecipeSection> = [.ingredients, .steps]

    /// The label the section is headed by.
    var label: LocalizedStringKey {
        switch self {
        case .ingredients: "Ingredients"
        case .cookware: "Cookware"
        case .steps: "Steps"
        }
    }
}
