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

    /// The number the first step of a group takes, counting from the top of the recipe.
    static func firstNumber(ofGroupAt index: Int, in recipe: Recipe) -> Int {
        recipe.groups.prefix(index).reduce(1, { $0 + $1.steps.count })
    }

    /// A step as a cook reads it, every annotation resolved to the words it stands for.
    static func prose(of step: Step) -> String {
        step.segments.map({ text(of: $0) }).joined()
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

    /// What one segment reads as, sigils and fences gone.
    private static func text(of segment: Segment) -> String {
        switch segment {
        case .text(let text):
            text

        case .ingredient(let ingredient):
            named(ingredient.name, after: ingredient.amount)

        case .cookware(let cookware):
            cookware.name

        case .timer(let timer):
            timer.text

        case .reference(let reference):
            named(reference.target, after: reference.amount)
        }
    }

    /// A name with the amount in front of it, or on its own where the annotation carries none.
    private static func named(_ name: String, after amount: Amount?) -> String {
        guard let amount else {
            return name
        }

        return "\(amount.text) \(name)"
    }
}
