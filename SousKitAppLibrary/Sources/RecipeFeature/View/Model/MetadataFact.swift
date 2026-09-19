import SwiftUI

/// A header value the recipe screen singles out, such as how many the recipe serves.
struct MetadataFact: Identifiable {
    /// What a fact tells.
    enum Kind: CaseIterable {
        case servings
        case prepTime
        case cookTime

        /// The header key the fact is read from.
        var key: String {
            switch self {
            case .servings: "servings"
            case .prepTime: "prep-time"
            case .cookTime: "cook-time"
            }
        }

        var label: LocalizedStringKey {
            switch self {
            case .servings: "Servings"
            case .prepTime: "Prep"
            case .cookTime: "Cook"
            }
        }

        var systemImage: String {
            switch self {
            case .servings: "person.2"
            case .prepTime: "clock"
            case .cookTime: "flame"
            }
        }
    }

    let kind: Kind

    /// The value as written in the header.
    let value: String

    var id: Kind {
        kind
    }
}
