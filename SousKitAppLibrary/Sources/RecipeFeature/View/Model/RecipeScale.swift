/// How much of a recipe to make: a number, and what that number counts.
struct RecipeScale: Hashable {
    /// What the number counts.
    let target: ScaleTarget

    /// The number, which multiplies the recipe where the target is the multiplier.
    let value: Double
}
