import RecipeLibrary

/// A screen the kitchen pushes on its navigation stack.
enum KitchenScreen: Hashable {
    /// What a folder holds, found by the names of the folders leading down to it, its own last.
    case folder([String])

    /// One recipe, as it is written.
    case recipe(RecipeEntry)
}
