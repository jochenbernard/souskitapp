import CookingFeature
import RecipeFeature

/// What the kitchen has open over its recipe list, kept so a cold start opens it again.
struct KitchenRestoration: Hashable, Codable {
    /// The id of the recipe pushed on the stack, looked up again so a cold start reads it as it is now, or `nil` while
    /// the recipe list is on top.
    let recipeID: String?

    /// What the recipe's screen has open, or `nil` while it stands as a push opened it.
    var recipe: RecipeFeatureRestoration?

    /// What cooking from the recipe has done, or `nil` while cooking is not open over the kitchen.
    var cooking: CookingFeatureRestoration?

    /// Whether the settings are open over the recipe list.
    var isShowingSettings = false
}
