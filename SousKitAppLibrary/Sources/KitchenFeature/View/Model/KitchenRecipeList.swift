import RecipeLibrary

/// What the kitchen has to show for the recipe directory.
enum KitchenRecipeList {
    /// The directory has not been read yet.
    case reading

    /// What the directory holds, which may be nothing.
    case recipes([RecipeFile])

    /// Reading the directory failed, with the reason to show.
    case failure(String)
}
