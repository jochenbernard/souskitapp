import SousKit

/// Gathers a recipe's ingredient annotations into the rows an ingredients list shows.
enum IngredientTotals {
    /// The rows for these ingredients, one to a name however a step capitalizes or accents it,
    /// with the amounts under a shared unit summed.
    static func rows(of ingredients: [Ingredient]) -> [IngredientRow] {
        var gathered: [(name: String, amounts: [Amount])] = []
        var indices: [String: Int] = [:]

        for ingredient in ingredients {
            let key = Normalization.normalized(ingredient.name)
            let index: Int

            if let known = indices[key] {
                index = known
            } else {
                index = gathered.count
                indices[key] = index
                gathered.append((ingredient.name, []))
            }

            if let amount = ingredient.amount {
                gathered[index].amounts.append(amount)
            }
        }

        return gathered.map({ IngredientRow(name: $0.name, amount: total(of: $0.amounts)) })
    }

    /// One term of a row: an amount as written, or the amounts sharing its unit summed into it.
    private struct Term {
        /// The unit these amounts carry, or `nil` where they carry none.
        let unit: String?

        /// The first of these amounts, as the recipe writes it.
        let text: String

        /// The low and the high of these amounts, or `nil` where the first holds no number.
        var bounds: (low: Double, high: Double)?

        /// Whether a second amount was summed into this term.
        var isSummed = false

        init(_ amount: Amount) {
            self.unit = amount.unit
            self.text = amount.text
            self.bounds = Self.bounds(of: amount.kind)
        }

        /// Whether an amount carrying the unit sums into this term.
        func sums(_ unit: String?) -> Bool {
            bounds != nil && self.unit == unit
        }

        /// The low and the high one amount covers, or `nil` where it holds no number to sum.
        private static func bounds(of kind: Amount.Kind) -> (low: Double, high: Double)? {
            switch kind {
            case let .precise(quantity): (quantity.value, quantity.value)
            case let .range(low, high): (low.value, high.value)
            case .imprecise: nil
            }
        }
    }

    /// What joins the amounts of a row that could not be summed into one.
    private static let separator = " + "

    /// What a row shows for these amounts, or `nil` where there are none.
    private static func total(of amounts: [Amount]) -> String? {
        guard !amounts.isEmpty else {
            return nil
        }

        return terms(of: amounts)
            .map(written)
            .joined(separator: separator)
    }

    /// The amounts gathered into terms, one per unit that can be summed and one per amount that cannot.
    private static func terms(of amounts: [Amount]) -> [Term] {
        var terms: [Term] = []

        for amount in amounts {
            let incoming = Term(amount)

            guard
                let added = incoming.bounds,
                let index = terms.firstIndex(where: { $0.sums(incoming.unit) }),
                let total = terms[index].bounds
            else {
                terms.append(incoming)
                continue
            }

            terms[index].bounds = (total.low + added.low, total.high + added.high)
            terms[index].isSummed = true
        }

        return terms
    }

    /// What one term reads as: the amount as written, or the sum where more than one was added.
    private static func written(_ term: Term) -> String {
        guard term.isSummed, let bounds = term.bounds else {
            return term.text
        }

        let total = bounds.low == bounds.high
            ? ScaleNumber.text(bounds.low)
            : "\(ScaleNumber.text(bounds.low))-\(ScaleNumber.text(bounds.high))"

        guard let unit = term.unit else {
            return total
        }

        return "\(total) \(unit)"
    }
}
