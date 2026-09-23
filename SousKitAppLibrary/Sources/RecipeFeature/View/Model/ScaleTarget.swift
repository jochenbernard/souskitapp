import SwiftUI

/// What a recipe is scaled by: the recipe itself, or a quantity its header declares.
enum ScaleTarget: Hashable {
    /// The recipe itself, multiplied.
    case multiplier

    /// The servings the header declares.
    case servings

    /// A yield the header declares, such as `1.8 kg` or `12 crepes`, in the unit it is written in,
    /// which is empty for a yield of a bare number.
    case yield(unit: String)

    /// What names the target among the others, which is the unit as written for a yield that has one.
    var name: Text {
        switch self {
        case .multiplier: Text("Multiplier", bundle: .module)
        case .servings: Text("Servings", bundle: .module)
        case .yield(let unit) where unit.isEmpty: Text("Yield", bundle: .module)
        case .yield(let unit): Text(verbatim: unit)
        }
    }

    /// What the number is labelled, which carries the unit for a yield that has one.
    var label: Text {
        guard case .yield(let unit) = self, !unit.isEmpty else {
            return name
        }

        return Text("Yield (\(unit))", bundle: .module)
    }

    /// What one tap of the plus adds, and one tap of the minus takes.
    ///
    /// A yield steps by a round share of what the recipe declares: a tenth, brought down to one, two
    /// or five of a power of ten, and never below one where the recipe declares a whole number. So
    /// 1.8 kg steps by 0.1 kg, 125 ml by 10 ml, and 12 crepes or 1 loaf by one.
    ///
    /// - Parameter declared: What the recipe declares of this target.
    /// - Returns: The step.
    func step(declared: Double) -> Double {
        switch self {
        case .multiplier:
            return 0.5

        case .servings:
            return 1.0

        case .yield:
            let tenth = declared / 10.0
            let power = pow(10.0, log10(tenth).rounded(.down))
            let round = [5.0, 2.0, 1.0].map({ $0 * power }).first(where: { $0 <= tenth }) ?? power

            return declared == declared.rounded() ? max(round, 1.0) : round
        }
    }

    /// What stepping stays between. Typing is held to none of it: any number above zero is a scale.
    ///
    /// - Parameter declared: What the recipe declares of this target.
    /// - Returns: The range.
    func stepRange(declared: Double) -> ClosedRange<Double> {
        switch self {
        case .multiplier: 0.5...99.0
        case .servings: 1.0...999.0
        case .yield: step(declared: declared)...(declared * 99.0)
        }
    }

    /// Where a step from the value lands.
    ///
    /// - Parameters:
    ///   - value: The number stepped from.
    ///   - steps: How many steps to take, which is -1 for the minus and 1 for the plus.
    ///   - declared: What the recipe declares of this target.
    /// - Returns: The number stepped to.
    func stepped(
        _ value: Double,
        by steps: Double,
        declared: Double
    ) -> Double {
        let range = stepRange(declared: declared)
        let clamped = min(
            max(value + steps * step(declared: declared), range.lowerBound),
            range.upperBound
        )

        // A number typed past the range stays put, rather than the minus pulling it back up into it.
        guard (clamped - value).sign == steps.sign || clamped == value else {
            return value
        }

        return clamped
    }
}
