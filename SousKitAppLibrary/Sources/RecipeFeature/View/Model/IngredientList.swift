import SousKit

/// A recipe's ingredients, split into those listed one per row and the staples named after them.
struct IngredientList {
    /// The ingredients to list one per row, in document order.
    let rows: [Ingredient]

    /// The staples written without an amount, each named once.
    let staples: [String]
}
