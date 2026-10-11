import SwiftUI

/// How much of a recipe to make: a number, and what that number counts.
public struct RecipeScale: Sendable, Hashable, Codable {
    /// What the number counts.
    public let target: ScaleTarget

    /// The number, which multiplies the recipe where the target is the multiplier.
    public let value: Double

    /// The scale read out, such as `12 servings` or `2×`.
    public var text: Text {
        let number = ScaleNumber.text(value)

        switch target {
        case .multiplier:
            return Text("\(number)×", bundle: .module)

        case .servings where number == "1":
            return Text("1 serving", bundle: .module)

        case .servings:
            return Text("\(number) servings", bundle: .module)

        case .yield(let unit) where unit.isEmpty:
            return Text(verbatim: number)

        case .yield(let unit):
            return Text(verbatim: "\(number) \(unit)")
        }
    }

    /// Creates a scale.
    ///
    /// - Parameters:
    ///   - target: What the number counts.
    ///   - value: The number.
    public init(target: ScaleTarget, value: Double) {
        self.target = target
        self.value = ScaleNumber.rounded(value)
    }
}
