import SousKit

/// What the recipe screen has to show for one recipe.
enum RecipeContent {
    /// The recipe has not been read yet.
    case reading

    /// The recipe, parsed.
    case recipe(Recipe)

    /// Reading the recipe failed, with the reason to show.
    case failure(String)
}
