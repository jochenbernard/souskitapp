import CookingFeature
import Foundation
import SousKit

/// The recipe being cooked from, beside the feature rendering it over the kitchen.
///
/// Built each time cooking starts, so every visit starts afresh, and identified by that visit, so the screen keeps
/// what it shows while it slides away.
struct OpenCooking: Identifiable {
    let id = UUID()
    let recipe: Recipe
    let feature: CookingFeature
}
