import RecipeFeature
import RecipeLibrary

/// The recipe pushed on the navigation stack, beside the feature rendering it.
///
/// The feature is built once, when the recipe is pushed. Building it in the navigation
/// destination instead would hand every redraw a fresh view model, and the recipe already read
/// into the old one would never reach the screen.
struct OpenRecipe {
    let recipeFile: RecipeFile
    let feature: RecipeFeature
}
