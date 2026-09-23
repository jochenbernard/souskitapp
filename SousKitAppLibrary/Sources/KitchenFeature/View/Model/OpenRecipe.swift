import RecipeFeature
import RecipeLibrary

/// The recipe last pushed on the navigation stack, beside the feature rendering it.
///
/// The feature is built when the recipe is pushed, each time it is. Building it in the navigation
/// destination instead would hand every redraw a fresh view model, and the recipe already read
/// into the old one would never reach the screen. It outlives the pop, which needs something to
/// draw while the screen animates away, until the next push replaces it.
struct OpenRecipe {
    let recipeEntry: RecipeEntry
    let feature: RecipeFeature
}
