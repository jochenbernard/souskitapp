/// What the kitchen has to show for the recipe repository.
enum KitchenRecipeList {
    /// The repository has not been read yet.
    case reading

    /// What the repository holds, as cards in the order they are shown, which may be none.
    case recipes([KitchenRecipeCard])

    /// Reading the repository failed, with the reason to show.
    case failure(String)
}
