import RecipeLibrary

extension KitchenScreen {
    /// The card that opens the screen.
    var cardID: KitchenCardID {
        switch self {
        case .folder(let path):
            .folder(path)

        case .recipe(let recipeEntry):
            .recipe(recipeEntry.id)
        }
    }
}
