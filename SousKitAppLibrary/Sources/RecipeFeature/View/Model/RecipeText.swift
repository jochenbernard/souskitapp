import RecipeLibrary

/// What the recipe screen has to show for one recipe.
enum RecipeText {
    /// The recipe has not been read yet.
    case reading

    /// The recipe, as it is written in the file.
    case text(String)

    /// Reading the recipe failed, with the reason to show.
    case failure(String)
}
