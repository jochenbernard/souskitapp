import CookingFeature
import Foundation

/// The feature cooking from a recipe over the kitchen.
///
/// Built each time cooking starts, so every visit starts afresh, and identified by that visit, so the screen keeps
/// what it shows while it slides away.
struct OpenCooking: Identifiable {
    let id = UUID()
    let feature: CookingFeature

    /// Whether cooking opens again as a cold start found it, rather than from the button that starts it.
    let isResumed: Bool
}
