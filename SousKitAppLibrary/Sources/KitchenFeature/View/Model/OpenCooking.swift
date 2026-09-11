import CookingFeature
import SousKit

/// The recipe last cooked from, beside the feature rendering it.
///
/// Built once and kept past the pop, for the reason ``OpenRecipe`` gives.
struct OpenCooking {
    let recipe: Recipe
    let feature: CookingFeature
}
