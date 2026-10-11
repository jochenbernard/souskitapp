import RecipeLibrary
import RecipeScaling

extension PreferredScale {
    /// The scale the scale sheet set, or `nil` for a yield, which recipes cannot open on.
    ///
    /// - Parameter scale: The scale set.
    init?(_ scale: RecipeScale) {
        switch scale.target {
        case .servings: self = .servings(scale.value)
        case .multiplier: self = .multiplier(scale.value)
        case .yield: return nil
        }
    }
}
