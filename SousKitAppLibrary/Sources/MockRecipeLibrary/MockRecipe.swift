import RecipeLibrary

/// One recipe ``MockRecipeRepository`` lists: what it holds, and where it starts out.
struct MockRecipe: Sendable {
    /// What the repository finds the recipe by, as a folder finds one by its file name, which no two recipes share.
    let id: String

    /// The recipe as it is written, or `nil` for the one whose fetch never lands.
    let text: String?

    /// Whether the recipe is on the device before anything reads it.
    let availability: RecipeAvailability

    /// The recipe's name, as a list shows it: the words of its id.
    var name: String {
        id.replacing("-", with: " ")
    }

    init(
        id: String,
        text: String?,
        availability: RecipeAvailability = .downloaded
    ) {
        self.id = id
        self.text = text
        self.availability = availability
    }
}
