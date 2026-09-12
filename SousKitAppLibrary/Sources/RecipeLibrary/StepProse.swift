import SousKit
import SwiftUI

/// A step's segments read as prose, every annotation resolved to the words it stands for.
public enum StepProse {
    /// A step as a cook reads it, sigils and fences gone.
    ///
    /// Every annotation comes back marked, since each is something the step reaches for. Only
    /// the prose between them reads plainly.
    ///
    /// - Parameter step: The step to read.
    /// - Returns: The runs the step reads as, in document order.
    public static func runs(of step: Step) -> [StepRun] {
        step.segments.map({ run(of: $0) })
    }

    /// A step set as prose, with everything it reaches for underlined.
    ///
    /// - Parameters:
    ///   - step: The step to read.
    ///   - annotationColor: The color an annotation is underlined in.
    /// - Returns: The prose, ready to set as a `Text`.
    public static func attributedProse(
        of step: Step,
        annotationColor: Color
    ) -> AttributedString {
        runs(of: step).reduce(into: AttributedString()) { prose, run in
            prose.append(attributed(run, annotationColor: annotationColor))
        }
    }

    /// One run, underlined where it stands for an annotation.
    private static func attributed(
        _ run: StepRun,
        annotationColor: Color
    ) -> AttributedString {
        var text = AttributedString(run.text)

        if run.isAnnotation {
            text.underlineStyle = Text.LineStyle(
                pattern: .solid,
                color: annotationColor
            )
        }

        return text
    }

    /// What one segment reads as, and whether it is an annotation.
    private static func run(of segment: Segment) -> StepRun {
        switch segment {
        case .text(let text):
            StepRun(text: text, isAnnotation: false)

        case .ingredient(let ingredient):
            StepRun(text: named(ingredient.name, after: ingredient.amount), isAnnotation: true)

        case .cookware(let cookware):
            StepRun(text: cookware.name, isAnnotation: true)

        case .timer(let timer):
            StepRun(text: timer.text, isAnnotation: true)

        case .reference(let reference):
            StepRun(text: named(reference.target, after: reference.amount), isAnnotation: true)
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
