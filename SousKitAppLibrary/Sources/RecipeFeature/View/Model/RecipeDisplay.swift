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
    /// A staple the list already has a row for is left to that row rather than named twice.
    static func ingredientList(of recipe: Recipe) -> IngredientList {
        let ingredients = recipe.ingredients
        let staples = ingredients.filter(isNamedAfter)
        let listed = ingredients.filter({ !isNamedAfter($0) })

        guard !listed.isEmpty else {
            return IngredientList(rows: IngredientTotals.rows(of: staples), staples: [])
        }

        let listedNames = Set(listed.map({ Normalization.normalized($0.name) }))

        return IngredientList(
            rows: IngredientTotals.rows(of: listed),
            staples: uniqueNames(staples.map(\.name))
                .filter({ !listedNames.contains(Normalization.normalized($0)) })
        )
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

    /// The language the screen is written in, which is the one it reads names and lists in.
    ///
    /// The screen's own strings, not the region: a name or a conjunction sits among that copy.
    private static let displayLocale = Locale(
        identifier: Bundle.module.preferredLocalizations.first ?? "en"
    )

    private static func facts(of metadata: Metadata) -> [MetadataFact] {
        MetadataFact.Kind.allCases.compactMap { kind in
            guard let value = metadata[kind.key], !value.isEmpty else {
                return nil
            }

            return MetadataFact(kind: kind, value: value)
        }
    }

    /// The allergens, which the specification does not name as a list key, read the way a list key is.
    private static func allergens(of metadata: Metadata) -> [String] {
        guard let value = metadata[allergensKey] else {
            return []
        }

        return listItems(of: value)
    }

    /// The header lines no fact, tag, or allergen shows, with the title left out.
    private static func metadataRows(of metadata: Metadata) -> [MetadataRow] {
        let shown = shownIndices(in: metadata.entries)

        return metadata.entries.enumerated().compactMap { index, entry in
            guard !shown.contains(index) else {
                return nil
            }

            return MetadataRow(
                id: index,
                key: entry.key,
                value: shownValue(of: entry)
            )
        }
    }

    /// Where the entries shown elsewhere sit: the title, the facts, the tags, and the allergens.
    ///
    /// Only the entry a reader sees is left out: a header repeating the key, or spelling it as a
    /// list, carries something the one value shown never shows, and dropping every line under that
    /// key loses it. Every `tags` line is left out, because every one of them merges into the chips.
    private static func shownIndices(in entries: [Metadata.Entry]) -> Set<Int> {
        var indices = Set(entries.indices.filter({ isTagList(entries[$0]) }))

        for key in [titleKey, allergensKey] + MetadataFact.Kind.allCases.map(\.key) {
            if let index = lastScalarIndex(of: key, in: entries) {
                indices.insert(index)
            }
        }

        return indices
    }

    /// Whether the entry is a `tags` line, whose items the chips hold.
    private static func isTagList(_ entry: Metadata.Entry) -> Bool {
        guard entry.key == tagsKey, case .list = entry.value else {
            return false
        }

        return true
    }

    /// Where the last scalar entry under a key sits, which is the one shown as that key's value.
    private static func lastScalarIndex(of key: String, in entries: [Metadata.Entry]) -> Int? {
        entries.lastIndex { entry in
            guard entry.key == key, case .scalar = entry.value else {
                return false
            }

            return true
        }
    }

    /// What a header line shows, with a language read as its name and anything else as written.
    private static func shownValue(of entry: Metadata.Entry) -> String {
        let text = value(of: entry.value)

        guard MetadataKey(key: entry.key) == .language else {
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
    ///
    /// A list opens with `[` and closes with the first unescaped `]`, which has to end the text,
    /// the reading the specification gives a list key.
    private static func inlineListContent(of text: String) -> Substring? {
        guard text.hasPrefix("[") else {
            return nil
        }

        let inner = text.dropFirst()
        var isEscaped = false

        for index in inner.indices {
            if isEscaped {
                isEscaped = false
            } else if inner[index] == "\\" {
                isEscaped = true
            } else if inner[index] == "]" {
                return index == inner.index(before: inner.endIndex) ? inner[..<index] : nil
            }
        }

        return nil
    }

    /// Whether the ingredient is a staple written without an amount, which is named after the list.
    private static func isNamedAfter(_ ingredient: Ingredient) -> Bool {
        ingredient.flags.isStaple && ingredient.amount == nil
    }

    /// The names in the order they are written, each kept once however the file writes it.
    private static func uniqueNames(_ names: [String]) -> [String] {
        var seen: Set<String> = []

        return names.filter({ seen.insert(Normalization.normalized($0)).inserted })
    }
}
