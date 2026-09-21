import SousKit

/// Rounds the numbers scaling writes past three decimals, which is as fine as a cook reads an amount.
struct AmountRounding {
    /// The header keys SousKit scales.
    private static let scaledKeys: Set<String> = ["servings", "yield"]

    private let parser: SousParser

    init(parser: SousParser) {
        self.parser = parser
    }

    /// The recipe with every number past three decimals rounded to three, in its steps and its header.
    ///
    /// A step's text keeps what scaling wrote, since only its segments are read.
    ///
    /// - Parameter recipe: A recipe as SousKit scaled it.
    /// - Returns: The recipe as a cook reads it.
    func rounded(_ recipe: Recipe) -> Recipe {
        var rounded = recipe

        rounded.metadata.entries = recipe.metadata.entries.map(roundedEntry)
        rounded.groups = recipe.groups.map { group in
            var group = group
            group.steps = group.steps.map { step in
                var step = step
                step.segments = step.segments.map(roundedSegment)

                return step
            }

            return group
        }

        return rounded
    }

    private func roundedEntry(_ entry: Metadata.Entry) -> Metadata.Entry {
        guard Self.scaledKeys.contains(entry.key) else {
            return entry
        }

        var rounded = entry

        switch entry.value {
        case .scalar(let text):
            rounded.value = .scalar(roundedValue(text))

        case .list(let items):
            rounded.value = .list(items.map(roundedValue))

        case .raw:
            break
        }

        return rounded
    }

    private func roundedSegment(_ segment: Segment) -> Segment {
        switch segment {
        case .ingredient(var ingredient):
            ingredient.amount = ingredient.amount.map(roundedAmount)

            return .ingredient(ingredient)

        case .reference(var reference):
            reference.amount = reference.amount.map(roundedAmount)

            return .reference(reference)

        case .text, .cookware, .timer:
            return segment
        }
    }

    /// A header value with its numbers rounded, or the value as it is where none needs it.
    private func roundedValue(_ text: String) -> String {
        let amount = parser.parseAmount(text)
        let rounded = roundedAmount(amount)

        return rounded == amount ? text : rounded.text
    }

    /// The amount with its numbers rounded, or the amount as it is where none needs it.
    private func roundedAmount(_ amount: Amount) -> Amount {
        guard !amount.isFixed, Self.quantities(of: amount.kind).contains(where: Self.isPastThreeDecimals) else {
            return amount
        }

        let numbers = Self.quantities(of: amount.kind).map({ ScaleNumber.text($0.value) })
        let written = [numbers.joined(separator: "-"), amount.unit].compactMap(\.self).joined(separator: " ")
        let read = parser.parseAmount(written)

        // A number rounded to nothing, or one reading back as another, keeps what scaling wrote.
        guard
            !numbers.contains("0"),
            read.unit == amount.unit,
            Self.quantities(of: read.kind).map(\.text) == numbers
        else {
            return amount
        }

        return read
    }

    private static func quantities(of kind: Amount.Kind) -> [Quantity] {
        switch kind {
        case .precise(let quantity): [quantity]
        case let .range(low, high): [low, high]
        case .imprecise: []
        }
    }

    private static func isPastThreeDecimals(_ quantity: Quantity) -> Bool {
        guard let point = quantity.text.firstIndex(of: ".") else {
            return false
        }

        return quantity.text[quantity.text.index(after: point)...].count > 3
    }
}
