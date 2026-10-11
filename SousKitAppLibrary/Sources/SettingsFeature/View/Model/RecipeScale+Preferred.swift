import RecipeLibrary
import RecipeScaling

extension RecipeScale {
    /// The scale recipes open on, as the scale sheet sets it.
    ///
    /// - Parameter preferredScale: The scale recipes open on.
    init(_ preferredScale: PreferredScale) {
        switch preferredScale {
        case .servings(let value): self.init(target: .servings, value: value)
        case .multiplier(let value): self.init(target: .multiplier, value: value)
        }
    }
}
