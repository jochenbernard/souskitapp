import RecipeLibrary

/// A screen the kitchen pushes on its navigation stack.
enum KitchenScreen: Hashable {
    /// One recipe, as it is written.
    case recipe(RecipeEntry)
}
