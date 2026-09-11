import RecipeLibrary
import SousKit

/// A screen the kitchen pushes on its navigation stack.
enum KitchenScreen: Hashable {
    /// One recipe, as it is written in the file.
    case recipe(RecipeFile)

    /// Cooking from one recipe, already read.
    case cooking(Recipe)
}
