/// One row of an ingredients list: an ingredient and what the recipe takes of it in all.
struct IngredientRow {
    /// The name, as the first annotation naming this ingredient writes it.
    let name: String

    /// What the recipe takes in all, or `nil` where no annotation carries an amount.
    let amount: String?
}
