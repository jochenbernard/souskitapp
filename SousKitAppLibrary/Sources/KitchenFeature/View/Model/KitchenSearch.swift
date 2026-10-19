/// What the kitchen's top screen shows for the text in its search field.
enum KitchenSearch: Hashable {
    /// No word is searched for, so the screen shows the top folder.
    case idle

    /// The recipes in every folder matching each word searched for, in the order shown, which may be none.
    case results([KitchenRecipeCard])
}
