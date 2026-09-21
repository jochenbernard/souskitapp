import CookingFeature
import SousKit

/// The recipe last cooked from, beside the feature rendering it.
///
/// Built on each push and kept past the pop, for the reason ``OpenRecipe`` gives.
struct OpenCooking {
    let recipe: Recipe
    let feature: CookingFeature
}
