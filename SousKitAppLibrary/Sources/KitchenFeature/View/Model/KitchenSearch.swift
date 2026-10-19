/// The text in a folder screen's search field, and the recipes it finds in that folder and the folders below it.
struct KitchenSearch: Hashable {
    /// The text in the field.
    let text: String

    /// Whether the text holds a word to search for, so the screen shows what it finds rather than its folder.
    let isSearching: Bool

    /// The recipes matching every word searched for, in the order shown, which may be none.
    let results: [KitchenRecipeCard]
}
