import SwiftUI

/// A scale read out, such as `12 servings` or `2×`.
struct ScaleValueText: View {
    private let scale: RecipeScale

    init(scale: RecipeScale) {
        self.scale = scale
    }

    var body: some View {
        switch scale.target {
        case .multiplier:
            Text("\(ScaleNumber.text(scale.value))×", bundle: .module)

        case .servings where scale.value == 1.0:
            Text("1 serving", bundle: .module)

        case .servings:
            Text("\(ScaleNumber.text(scale.value)) servings", bundle: .module)

        case .yield(let unit):
            Text(verbatim: "\(ScaleNumber.text(scale.value)) \(unit)")
        }
    }
}

#Preview("Scale values") {
    VStack(alignment: .leading) {
        ForEach(
            [
                RecipeScale(target: .multiplier, value: 2.0),
                RecipeScale(target: .multiplier, value: 0.5),
                RecipeScale(target: .servings, value: 1.0),
                RecipeScale(target: .servings, value: 12.0),
                RecipeScale(target: .yield(unit: "kg"), value: 3.6)
            ],
            id: \.self
        ) { scale in
            ScaleValueText(scale: scale)
        }
    }
}
