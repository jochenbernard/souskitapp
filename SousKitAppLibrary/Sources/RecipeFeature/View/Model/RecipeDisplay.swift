import Foundation
import SousKit

/// The parts of a recipe that take shaping before a view can lay them out.
enum RecipeDisplay {
    /// The header, sorted into facts, tags, allergens, and the lines left over.
    static func metadata(of metadata: Metadata) -> MetadataDisplay {
        MetadataDisplay(
            facts: facts(of: metadata),
            tags: metadata.tags,
            allergens: allergens(of: metadata),
            rows: metadataRows(of: metadata)
        )
    }

    /// The ingredients to list, with the staples written without an amount named after them.
    ///
    /// Where every ingredient is such a staple, they are all listed and none is named after.
    static func ingredientList(of recipe: Recipe) -> IngredientList {
        let staples = recipe.ingredients.filter({ $0.flags.isStaple && $0.amount == nil })
        let rows = recipe.ingredients.filter({ !$0.flags.isStaple || $0.amount != nil })

        guard !rows.isEmpty else {
            return IngredientList(rows: staples, staples: [])
        }

        return IngredientList(rows: rows, staples: uniqueNames(staples.map(\.name)))
    }

    /// Items joined into a list in the language the screen is shown in, such as "salt and black pepper".
    static func joinedList(_ items: [String]) -> String {
        items.formatted(.list(type: .and).locale(displayLocale))
    }

    /// The cookware in document order, each piece named once however often it is reached for.
    static func cookwareNames(of recipe: Recipe) -> [String] {
        uniqueNames(recipe.cookware.map(\.name))
    }

    private static let titleKey = "title"

    private static let tagsKey = "tags"

    private static let allergensKey = "allergens"

    private static let languageKey = "language"

    /// The language the screen is written in, which is the one it reads names and lists in.
    private static var displayLocale: Locale {
        // Not the region's language: a name or a conjunction would sit in copy written in another.
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    }

    private static func facts(of metadata: Metadata) -> [MetadataFact] {
        MetadataFact.Kind.allCases.compactMap { kind in
            guard let value = lastScalar(kind.key, in: metadata), !value.isEmpty else {
                return nil
            }

            return MetadataFact(kind: kind, value: value)
        }
    }

    /// The allergens, which the specification does not name as a list key, read the way a list key is.
    private static func allergens(of metadata: Metadata) -> [String] {
        guard let value = lastScalar(allergensKey, in: metadata) else {
            return []
        }

        return listItems(of: value)
    }

    /// The header lines no fact, tag, or allergen shows, with the title left out.
    private static func metadataRows(of metadata: Metadata) -> [MetadataRow] {
        let titleIndex = indexOfTitle(in: metadata.entries)
        let shownKeys = Set(MetadataFact.Kind.allCases.map(\.key) + [tagsKey, allergensKey])

        return metadata.entries.enumerated().compactMap { index, entry in
            guard index != titleIndex, !shownKeys.contains(entry.key) else {
                return nil
            }

            return MetadataRow(
                id: index,
                key: entry.key,
                value: shownValue(of: entry)
            )
        }
    }

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

    private static func lastScalar(_ key: String, in metadata: Metadata) -> String? {
        metadata.entries.last(where: { $0.key == key }).flatMap { entry in
            guard case .scalar(let text) = entry.value else {
                return nil
            }

            return text
        }
    }

    /// What a header line shows, with a language read as its name and anything else as written.
    private static func shownValue(of entry: Metadata.Entry) -> String {
        let text = value(of: entry.value)

        guard entry.key == languageKey else {
            return text
        }

        return displayLocale.localizedString(forIdentifier: text) ?? text
    }

    /// What one header entry reads as on a single line.
    private static func value(of value: Metadata.Entry.Value) -> String {
        switch value {
        case .scalar(let text): text
        case .list(let items): items.joined(separator: ", ")
        case .raw(let text): text.trimmingCharacters(in: .whitespaces)
        }
    }

    /// The items of a value, where `[a, b]` is an inline list and anything else is one item.
    ///
    /// Within the brackets a backslash escapes `,`, `[`, `]`, and itself, and is kept before
    /// anything else.
    private static func listItems(of text: String) -> [String] {
        guard let inner = inlineListContent(of: text) else {
            return text.isEmpty ? [] : [text]
        }

        var items: [String] = []
        var item = ""
        var isEscaped = false

        for character in inner {
            if isEscaped {
                item += ",[]\\".contains(character) ? String(character) : "\\\(character)"
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "," {
                items.append(item)
                item = ""
            } else {
                item.append(character)
            }
        }

        items.append(item)

        return items
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
    }

    /// What lies between the brackets of an inline list, or `nil` when the text is not one.
    private static func inlineListContent(of text: String) -> Substring? {
        guard text.count >= 2, text.hasPrefix("["), text.hasSuffix("]") else {
            return nil
        }

        let inner = text.dropFirst().dropLast()
        let trailingBackslashes = inner.reversed().prefix(while: { $0 == "\\" }).count

        return trailingBackslashes.isMultiple(of: 2) ? inner : nil
    }

    private static func uniqueNames(_ names: [String]) -> [String] {
        var seen: Set<String> = []

        return names.filter({ seen.insert($0).inserted })
    }
}
