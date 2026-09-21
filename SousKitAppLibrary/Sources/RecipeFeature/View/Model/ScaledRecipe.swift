import Foundation
import SousKit

/// A recipe as its file writes it, beside what it comes to at the scale a cook chose.
struct ScaledRecipe {
    /// The recipe as it was read, which every scale is taken from rather than compounded on.
    let asWritten: Recipe

    /// How much of it to make.
    private(set) var scale: RecipeScale

    /// The recipe at that scale with its numbers to three decimals, or ``asWritten`` itself at the ``defaultScale``.
    private(set) var scaled: Recipe

    /// Each of the ``targets``, at what the header declares of it.
    private let declaredScales: [RecipeScale]

    /// What ``scaled`` multiplies the recipe as written by, kept apart from the rounded ``scale``.
    private var factor: Double

    private let parser: SousParser

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

    /// How SousKit reads a number, in its own notation rather than the reader's.
    private static let sousNumberStyle = FloatingPointFormatStyle<Double>()
        // A point on a whole number keeps `3 1/2-litre jars` from reading as three and a half.
        .precision(.fractionLength(1...6))
        .grouping(.never)
        .locale(Locale(identifier: "en_US_POSIX"))

    /// A recipe at a scale, or at its ``defaultScale``, the scale its file writes it in, where no scale
    /// is given or it does not scale that way.
    ///
    /// - Parameters:
    ///   - asWritten: The recipe as it was read.
    ///   - parser: What the scaled amounts are read back with.
    ///   - scale: How much of it to make.
    init(
        asWritten: Recipe,
        parser: SousParser,
        scale: RecipeScale? = nil
    ) {
        let atDefault = Self(
            asWritten: asWritten,
            declaredScales: Self.declaredScales(of: asWritten, parser: parser),
            parser: parser
        )

        self = scale.flatMap(atDefault.rescaled(to:)) ?? atDefault
    }

    private init(
        asWritten: Recipe,
        declaredScales: [RecipeScale],
        parser: SousParser
    ) {
        self.asWritten = asWritten
        self.declaredScales = declaredScales
        self.scale = declaredScales[0]
        self.scaled = asWritten
        self.factor = 1.0
        self.parser = parser
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

    /// The recipe taken to another scale, or `nil` where it does not scale that way.
    ///
    /// - Parameter scale: How much of it to make.
    /// - Returns: The recipe at that scale.
    func rescaled(to scale: RecipeScale) -> Self? {
        guard scale != defaultScale else {
            return Self(
                asWritten: asWritten,
                declaredScales: declaredScales,
                parser: parser
            )
        }

        guard
            let declared = declared(of: scale.target),
            let moved = Self.scaled(asWritten, to: scale, parser: parser)
        else {
            return nil
        }

        var rescaled = self
        rescaled.scale = scale
        rescaled.scaled = AmountRounding(parser: parser).rounded(moved)
        rescaled.factor = scale.value / declared

        return rescaled
    }

    /// The same food counted on another target, or `nil` where the recipe has no such target.
    ///
    /// - Parameter target: The target to count by.
    /// - Returns: The recipe, unmoved, at what the scale in force comes to on that target.
    func counted(by target: ScaleTarget) -> Self? {
        guard let value = value(of: target) else {
            return nil
        }

        var counted = self
        counted.scale = RecipeScale(target: target, value: value)

        return counted
    }

    /// Each target SousKit scales the recipe toward, at what the header declares of it, then the multiplier.
    private static func declaredScales(of recipe: Recipe, parser: SousParser) -> [RecipeScale] {
        let servings = recipe.metadata.servings.map({ [RecipeScale(target: .servings, value: $0)] }) ?? []
        let yields = declaredYields(of: recipe, besideServings: !servings.isEmpty)

        // A trial at what the header declares finds a range, a zero, and a unit declared twice over.
        let scalable = (servings + yields).filter({ scaled(recipe, to: $0, parser: parser) != nil })

        return scalable + [RecipeScale(target: .multiplier, value: 1.0)]
    }

    /// The first yield in each unit with a single number to count from, in the order the header writes them.
    private static func declaredYields(of recipe: Recipe, besideServings: Bool) -> [RecipeScale] {
        var yields: [RecipeScale] = []

        for amount in recipe.metadata.yields {
            // A yield with no unit, such as `12`, is declared under the empty one.
            let unit = amount.unit ?? ""

            guard
                // A yield in servings is the servings target where the header declares one.
                !besideServings || unit != "servings",
                case .precise(let quantity) = amount.kind,
                !yields.contains(where: { $0.target == .yield(unit: unit) })
            else {
                continue
            }

            yields.append(RecipeScale(target: .yield(unit: unit), value: quantity.value))
        }

        return yields
    }

    /// The recipe at the scale, or `nil` where the scale is unusable or the header cannot carry it.
    private static func scaled(
        _ recipe: Recipe,
        to scale: RecipeScale,
        parser: SousParser
    ) -> Recipe? {
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
            let target = parser.parseAmount("\(scale.value.formatted(sousNumberStyle)) \(unit)")

            return try? recipe.scaled(to: target)
        }
    }
}
