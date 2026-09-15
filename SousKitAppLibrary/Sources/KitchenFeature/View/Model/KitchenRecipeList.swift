import RecipeLibrary

/// What the kitchen has to show for the recipe repository.
enum KitchenRecipeList {
    /// The repository has not been read yet.
    case reading

    /// What the repository holds, which may be nothing.
    case recipes([RecipeEntry])

    /// Reading the repository failed, with the reason to show.
    case failure(String)
}
