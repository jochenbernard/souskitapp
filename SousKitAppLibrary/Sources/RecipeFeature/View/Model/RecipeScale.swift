/// How much of a recipe to make: a number, and what that number counts.
struct RecipeScale: Hashable {
    /// What the number counts.
    let target: ScaleTarget

    /// The number, which multiplies the recipe where the target is the multiplier.
    let value: Double

    init(target: ScaleTarget, value: Double) {
        self.target = target
        // Steps and switched targets land on 1.9000000000000001, which is not a number anyone typed.
        self.value = (value * 1_000_000.0).rounded() / 1_000_000.0
    }
}
