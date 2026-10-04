import RecipeFeature

/// What the kitchen has open over its recipe list, kept so a cold start opens it again.
struct KitchenRestoration: Hashable, Codable {
    /// The id of the recipe pushed on the stack, looked up again so a cold start reads it as it is now.
    let recipeID: String

    /// What the recipe's screen has open, or `nil` while it stands as a push opened it.
    var recipe: RecipeFeatureRestoration?

    /// Whether cooking from the recipe is open over the kitchen.
    var isCooking: Bool
}
