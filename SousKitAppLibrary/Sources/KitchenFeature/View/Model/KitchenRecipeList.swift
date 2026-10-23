/// What the kitchen has to show for the recipe repository.
enum KitchenRecipeList {
    /// The repository has not been read yet.
    case reading

    /// What the repository holds, from its top folder down, which may be nothing.
    case recipes(KitchenFolder)

    /// Reading the repository failed, with the reason to show.
    case failure(String)
}
