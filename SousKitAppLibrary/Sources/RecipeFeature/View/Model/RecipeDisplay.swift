import Foundation
import SousKit

/// The parts of a recipe that take shaping before a view can lay them out.
enum RecipeDisplay {
    /// The header lines to show, with the title left out because it heads the screen.
    static func metadataRows(of metadata: Metadata) -> [MetadataRow] {
        let titleIndex = indexOfTitle(in: metadata.entries)

        return metadata.entries.enumerated().compactMap { index, entry in
            guard index != titleIndex else {
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

    /// Where the entry the screen heads itself with sits, which is the last scalar `title`.
    ///
    /// Only that one entry is left out: a header repeating the key, or spelling it as a list,
    /// carries something the title never shows, and dropping every `title` line loses it.
    private static func indexOfTitle(in entries: [Metadata.Entry]) -> Int? {
        entries.lastIndex { entry in
            guard entry.key == titleKey, case .scalar = entry.value else {
                return false
            }

            return true
        }
    }

    /// What one header entry reads as on a single line.
    private static func value(of value: Metadata.Entry.Value) -> String {
        switch value {
        case .scalar(let text): text
        case .list(let items): items.joined(separator: ", ")
        case .raw(let text): text.trimmingCharacters(in: .whitespaces)
        }
    }
}
