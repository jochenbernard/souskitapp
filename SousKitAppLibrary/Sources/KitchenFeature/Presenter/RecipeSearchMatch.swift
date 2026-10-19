/// Where a search found a recipe, ordered from the closest match to the loosest.
enum RecipeSearchMatch: Comparable, CaseIterable {
    /// Every word searched for begins a word of the title.
    case title

    /// Every word searched for begins a word of the title or of a tag, and one of them only a tag's.
    case tag

    /// Every word searched for begins a word of the title, a tag or an ingredient's name, and one of them only an
    /// ingredient's.
    case ingredient
}
