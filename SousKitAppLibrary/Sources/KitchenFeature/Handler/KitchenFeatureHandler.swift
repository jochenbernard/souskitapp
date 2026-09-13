/// What ``KitchenFeature`` reports out of the kitchen to.
public protocol KitchenFeatureHandler {
    /// The debug menu's reset was confirmed, and what the app remembers is to go.
    @MainActor
    func kitchenFeatureDidConfirmReset()
}
