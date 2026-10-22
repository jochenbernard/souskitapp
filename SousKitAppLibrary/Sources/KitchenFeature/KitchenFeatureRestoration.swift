import CookingFeature
import RecipeFeature

/// What the kitchen has open over its recipe list, kept so a cold start opens it again.
public struct KitchenFeatureRestoration: Sendable, Hashable, Codable {
    /// The names of the folders leading down to the folder pushed last, each of them pushed under it, or none where
    /// no folder is pushed.
    let folderPath: [String]

    /// The id of the recipe pushed over the folders, looked up again so a cold start reads it as it is now, or `nil`
    /// where none is pushed.
    let recipeID: String?

    /// How the recipe's screen was left, or `nil` while it stands as a push opened it.
    var recipe: RecipeFeatureRestoration?

    /// What cooking from the recipe has done, or `nil` while cooking is not open over the kitchen.
    var cooking: CookingFeatureRestoration?

    /// Whether a recipe is pushed, over the folders or the recipe list.
    public var isShowingRecipe: Bool {
        recipeID != nil
    }

    init(
        folderPath: [String] = [],
        recipeID: String? = nil,
        recipe: RecipeFeatureRestoration? = nil,
        cooking: CookingFeatureRestoration? = nil
    ) {
        self.folderPath = folderPath
        self.recipeID = recipeID
        self.recipe = recipe
        self.cooking = cooking
    }
}
