/// What ``KitchenFeature`` reports out of the kitchen to.
public protocol KitchenFeatureHandler {
    /// Whether something is open over the kitchen, which pushes no recipe under it.
    @MainActor
    var kitchenFeatureIsCovered: Bool { get }

    /// What the kitchen has open changed.
    ///
    /// - Parameter restoration: What a cold start opens again, or `nil` on the recipe list with nothing over it.
    @MainActor
    func kitchenFeatureDidChangeRestoration(_ restoration: KitchenFeatureRestoration?)

    /// The kitchen opened what it was built to open again.
    @MainActor
    func kitchenFeatureDidRestore()
}
