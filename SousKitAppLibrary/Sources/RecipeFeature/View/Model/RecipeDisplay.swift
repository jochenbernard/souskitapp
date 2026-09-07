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
    ///
    /// Every annotation comes back underlined, since each is something the step reaches for.
    /// Only the prose between them reads plainly.
    static func runs(of step: Step) -> [StepRun] {
        step.segments.map({ run(of: $0) })
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

    /// What one segment reads as, sigils and fences gone, and whether it is underlined.
    private static func run(of segment: Segment) -> StepRun {
        switch segment {
        case .text(let text):
            StepRun(text: text, isUnderlined: false)

        case .ingredient(let ingredient):
            StepRun(text: named(ingredient.name, after: ingredient.amount), isUnderlined: true)

        case .cookware(let cookware):
            StepRun(text: cookware.name, isUnderlined: true)

        case .timer(let timer):
            StepRun(text: timer.text, isUnderlined: true)

        case .reference(let reference):
            StepRun(text: named(reference.target, after: reference.amount), isUnderlined: true)
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
