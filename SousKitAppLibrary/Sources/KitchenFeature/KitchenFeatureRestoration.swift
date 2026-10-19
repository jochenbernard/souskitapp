import CookingFeature
import RecipeFeature

/// What the kitchen has open over its recipe list, kept so a cold start opens it again.
public struct KitchenFeatureRestoration: Sendable, Hashable, Codable {
    /// The id of the recipe pushed on the stack, looked up again so a cold start reads it as it is now.
    let recipeID: String

    /// How the recipe's screen was left, or `nil` while it stands as a push opened it.
    var recipe: RecipeFeatureRestoration?

    /// What cooking from the recipe has done, or `nil` while cooking is not open over the kitchen.
    var cooking: CookingFeatureRestoration?
}
