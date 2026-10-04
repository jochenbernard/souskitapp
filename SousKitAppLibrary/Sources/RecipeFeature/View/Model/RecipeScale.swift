import SwiftUI

/// How much of a recipe to make: a number, and what that number counts.
struct RecipeScale: Hashable, Codable {
    /// What the number counts.
    let target: ScaleTarget

    /// The number, which multiplies the recipe where the target is the multiplier.
    let value: Double

    /// The scale read out, such as `12 servings` or `2×`.
    var text: Text {
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

    init(target: ScaleTarget, value: Double) {
        self.target = target
        // Steps and switched targets land on 1.9000000000000001, which is not a number anyone typed.
        self.value = (value * 1_000_000.0).rounded() / 1_000_000.0
    }
}
