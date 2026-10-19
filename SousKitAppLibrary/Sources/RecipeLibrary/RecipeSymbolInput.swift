import CryptoKit
import Foundation
import SousKit

/// What a recipe's symbol is picked from: what its header says it is, and what it is made of.
public struct RecipeSymbolInput: Sendable, Hashable {
    // Enough to tell a dish by, and a long ingredient list stays out of the prompt.
    private static let ingredientNameLimit = 20
    private static let fieldSeparator = "\u{1F}"
    private static let itemSeparator = "\u{1E}"
    private static let hexDigits = Array("0123456789abcdef")

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
        self.digest = Self.digest(
            title: title,
            tags: tags,
            course: course,
            cuisine: cuisine,
            ingredientNames: ingredientNames
        )
    }

    private static func digest(
        title: String,
        tags: [String],
        course: String?,
        cuisine: String?,
        ingredientNames: [String]
    ) -> String {
        let text = [
            title,
            tags.joined(separator: itemSeparator),
            course ?? "",
            cuisine ?? "",
            ingredientNames.joined(separator: itemSeparator)
        ]
        .joined(separator: fieldSeparator)
        let hex = SHA256.hash(data: Data(text.utf8)).flatMap { byte in
            [hexDigits[Int(byte >> 4)], hexDigits[Int(byte & 0x0F)]]
        }

        return String(hex)
    }
}
