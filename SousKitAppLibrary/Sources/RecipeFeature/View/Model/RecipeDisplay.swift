import Foundation
import SousKit

/// The parts of a recipe that take shaping before a view can lay them out.
enum RecipeDisplay {
    /// The header lines to show, with the title left out because it heads the screen.
    static func metadataRows(of metadata: Metadata) -> [MetadataRow] {
        metadata.entries.enumerated().compactMap { index, entry in
            guard entry.key != titleKey else {
                return nil
            }

            return MetadataRow(id: index, key: entry.key, value: value(of: entry.value))
        }
    }

    /// The cookware in document order, each piece named once however often it is reached for.
    static func cookwareNames(of recipe: Recipe) -> [String] {
        var seen: Set<String> = []

        return recipe.cookware.compactMap({ seen.insert($0.name).inserted ? $0.name : nil })
    }

    private static let titleKey = "title"

    /// What one header entry reads as on a single line.
    private static func value(of value: Metadata.Entry.Value) -> String {
        switch value {
        case .scalar(let text): text
        case .list(let items): items.joined(separator: ", ")
        case .raw(let text): text.trimmingCharacters(in: .whitespaces)
        }
    }
}
