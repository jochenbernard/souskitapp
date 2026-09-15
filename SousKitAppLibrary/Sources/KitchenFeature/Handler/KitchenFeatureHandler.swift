/// What ``KitchenFeature`` reports out of the kitchen to.
public protocol KitchenFeatureHandler {
    /// A reset of the app was confirmed, and what the app remembers is to go.
    @MainActor
    func kitchenFeatureDidConfirmReset()
}
