import CryptoKit
import Foundation
import SousKit

/// What a recipe's symbol is picked from: what its header says it is, and what it is made of.
public struct RecipeSymbolInput: Sendable, Hashable {
    // Enough to tell a dish by, and a long ingredient list stays out of the prompt.
    private static let ingredientNameLimit = 20
    private static let fieldSeparator = "\u{1F}"
    private static let itemSeparator = "\u{1E}"

    /// The title the recipe shows.
    public let title: String

    /// The header's tags.
    public let tags: [String]

    /// The header's course, or `nil` where it names none.
    public let course: String?

    /// The header's cuisine, or `nil` where it names none.
    public let cuisine: String?

    /// The names of the first ingredients the recipe is made of.
    public let ingredientNames: [String]

    /// A digest of every field, the same on every launch and device.
    let digest: String

    /// Creates the input for a listed recipe.
    ///
    /// - Parameter listedRecipe: The recipe.
    /// - Returns: The input, or `nil` where the recipe's contents have not been read.
    public init?(listedRecipe: ListedRecipe) {
        guard let metadata = listedRecipe.entry.summary?.metadata else {
            return nil
        }

        self.title = listedRecipe.entry.title
        self.tags = metadata.tags
        self.course = metadata["course"].flatMap({ $0.isEmpty ? nil : $0 })
        self.cuisine = metadata["cuisine"].flatMap({ $0.isEmpty ? nil : $0 })
        self.ingredientNames = Array(listedRecipe.ingredientNames.prefix(Self.ingredientNameLimit))
        // Made once, since every listing compares every recipe's input with its pick.
        let text = [
            title,
            tags.joined(separator: Self.itemSeparator),
            course ?? "",
            cuisine ?? "",
            ingredientNames.joined(separator: Self.itemSeparator)
        ]
        .joined(separator: Self.fieldSeparator)
        self.digest = SHA256.hash(data: Data(text.utf8)).map({ String(format: "%02x", $0) }).joined()
    }
}
