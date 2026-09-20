/// A recipe's ingredients, split into those listed one per row and the staples named after them.
struct IngredientList {
    /// The ingredients to list, one row per name, in the order the recipe first names them.
    let rows: [IngredientRow]

    /// The staples written without an amount, each named once.
    let staples: [String]
}
