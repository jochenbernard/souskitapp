/// What ``CookingFeature`` reports to.
public protocol CookingFeatureHandler {
    /// A cook confirmed leaving the cooking screen.
    @MainActor
    func cookingFeatureDidExit()
}
