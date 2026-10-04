import RecipeFeature
import RecipeLibrary

/// What the kitchen has open over its recipe list, kept so a cold start opens it again.
struct KitchenRestoration: Hashable, Codable {
    /// The recipe pushed on the stack.
    let recipeEntry: RecipeEntry

    /// What the recipe's screen has open, or `nil` while it stands as a push opened it.
    var recipe: RecipeFeatureRestoration?

    /// Whether cooking from the recipe is open over the kitchen.
    var isCooking: Bool
}
