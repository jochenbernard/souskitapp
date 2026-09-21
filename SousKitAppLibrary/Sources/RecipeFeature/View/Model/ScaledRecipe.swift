import Foundation
import SousKit

/// A recipe as its file writes it, beside what it comes to at the scale a cook chose.
struct ScaledRecipe {
    /// The recipe as it was read, which every scale is taken from rather than compounded on.
    let asWritten: Recipe

    /// How much of it to make.
    let scale: RecipeScale

    /// The recipe at that scale, which is ``asWritten`` itself where nothing moves.
    let scaled: Recipe

    /// Each of the ``targets``, at what the header declares of it.
    private let declaredScales: [RecipeScale]

    /// The targets this recipe can be scaled by, in the order a cook reaches for them: the servings,
    /// then the yields, then the multiplier, which every recipe has.
    var targets: [ScaleTarget] {
        declaredScales.map(\.target)
    }

    /// The scale the recipe opens on: the first of its ``targets``, at what the header declares of it.
    var defaultScale: RecipeScale {
        declaredScales[0]
    }

    /// Whether the recipe stands at its ``defaultScale``, which leaves nothing to reset.
    var isDefault: Bool {
        scale == defaultScale
    }

    /// What the scale in force multiplies every amount by.
    private var factor: Double {
        guard let declared = declared(of: scale.target), declared > 0.0 else {
            return 1.0
        }

        return scale.value / declared
    }

    /// How SousKit reads a number, in its own notation rather than the reader's.
    private static let sousNumberStyle = FloatingPointFormatStyle<Double>()
        .precision(.fractionLength(0...6))
        .grouping(.never)
        .locale(Locale(identifier: "en_US_POSIX"))

    /// A recipe at a scale, or at its ``defaultScale``, the scale its file writes it in, where no scale
    /// is given or it does not scale that way.
    ///
    /// - Parameters:
    ///   - asWritten: The recipe as it was read.
    ///   - scale: How much of it to make.
    init(asWritten: Recipe, scale: RecipeScale? = nil) {
        self.asWritten = asWritten
        self.declaredScales = Self.declaredScales(of: asWritten)

        if let scale, let recipe = Self.scaled(asWritten, to: scale) {
            self.scale = scale
            self.scaled = recipe
        } else {
            self.scale = self.declaredScales[0]
            self.scaled = asWritten
        }
    }

    /// What the header declares of a target, or `nil` where it declares none to scale toward.
    ///
    /// - Parameter target: The target to read.
    /// - Returns: What one of the recipe as written is worth on that target.
    func declared(of target: ScaleTarget) -> Double? {
        declaredScales.first(where: { $0.target == target })?.value
    }

    /// What the scale in force comes to on a target, or `nil` where the recipe has no such target.
    ///
    /// - Parameter target: The target to read.
    /// - Returns: The number that target stands at.
    func value(of target: ScaleTarget) -> Double? {
        declared(of: target).map({ $0 * factor })
    }

    /// The scale a step from the one in force lands on, on the same target.
    ///
    /// - Parameter steps: How many steps to take, which is -1 for the minus and 1 for the plus.
    /// - Returns: The scale stepped to.
    func stepped(by steps: Double) -> RecipeScale {
        RecipeScale(
            target: scale.target,
            value: scale.target.stepped(
                scale.value,
                by: steps,
                declared: declared(of: scale.target) ?? 1.0
            )
        )
    }

    private static func declaredScales(of recipe: Recipe) -> [RecipeScale] {
        let servings = declaredServings(of: recipe).map({ [RecipeScale(target: .servings, value: $0)] }) ?? []
        let yields = declaredYields(of: recipe).map({ RecipeScale(target: .yield(unit: $0.unit), value: $0.value) })

        return servings + yields + [RecipeScale(target: .multiplier, value: 1.0)]
    }

    /// The servings the header declares, or `nil` where it declares none to scale toward.
    private static func declaredServings(of recipe: Recipe) -> Double? {
        guard let servings = recipe.metadata.servings, servings > 0.0 else {
            return nil
        }

        return servings
    }

    /// The yields a cook can scale toward, in the order the header writes them.
    ///
    /// SousKit scales to a yield of a single number in a unit the header does not contradict, so a
    /// range, an amount with no number, and a unit declared twice over are left out. So is a yield in
    /// servings where the header declares servings already.
    private static func declaredYields(of recipe: Recipe) -> [(unit: String, value: Double)] {
        var yields: [(unit: String, value: Double)] = []
        var contradicted: Set<String> = []

        for amount in recipe.metadata.yields {
            guard
                let unit = amount.unit,
                !unit.isEmpty,
                case .precise(let quantity) = amount.kind,
                quantity.value > 0.0
            else {
                continue
            }

            if let known = yields.first(where: { $0.unit == unit }) {
                if known.value != quantity.value {
                    contradicted.insert(unit)
                }
            } else {
                yields.append((unit, quantity.value))
            }
        }

        let servings = declaredServings(of: recipe)

        return yields.filter { yield in
            !contradicted.contains(yield.unit) && (servings == nil || yield.unit != "servings")
        }
    }

    /// The recipe at the scale, or `nil` where the scale is unusable or the header cannot carry it.
    private static func scaled(_ recipe: Recipe, to scale: RecipeScale) -> Recipe? {
        // Zero is a factor SousKit takes, and a recipe of nothing is not one to cook from.
        guard scale.value > 0.0, scale.value.isFinite else {
            return nil
        }

        switch scale.target {
        case .multiplier:
            return try? recipe.scaled(by: scale.value)

        case .servings:
            return try? recipe.scaled(toServings: scale.value)

        case .yield(let unit):
            let target = SousParser().parseAmount("\(scale.value.formatted(sousNumberStyle)) \(unit)")

            return try? recipe.scaled(to: target)
        }
    }
}
