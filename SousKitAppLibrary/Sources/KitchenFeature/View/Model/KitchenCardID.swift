/// What a card on a page of the kitchen is known by, the same however its recipe is listed later, such as with a
/// picture a download brought.
enum KitchenCardID: Hashable {
    /// A folder's card, by the names of the folders leading down to it, its own last.
    case folder([String])

    /// A recipe's card, by the recipe's id.
    case recipe(String)
}
