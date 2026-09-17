import SwiftUI

/// A section of the recipe screen that opens and closes.
enum RecipeSection: Hashable {
    case ingredients
    case cookware

    static let openByDefault: Set<RecipeSection> = [.ingredients]

    var label: LocalizedStringKey {
        switch self {
        case .ingredients: "Ingredients"
        case .cookware: "Cookware"
        }
    }
}
