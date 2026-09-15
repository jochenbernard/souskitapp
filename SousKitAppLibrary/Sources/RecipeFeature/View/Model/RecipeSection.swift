import SwiftUI

/// A section of the recipe screen that opens and closes.
enum RecipeSection: Hashable {
    case ingredients
    case cookware
    case steps

    static let openByDefault: Set<RecipeSection> = [.ingredients, .steps]

    var label: LocalizedStringKey {
        switch self {
        case .ingredients: "Ingredients"
        case .cookware: "Cookware"
        case .steps: "Steps"
        }
    }
}
