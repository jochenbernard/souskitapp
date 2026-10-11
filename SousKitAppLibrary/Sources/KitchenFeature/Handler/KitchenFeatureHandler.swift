/// What ``KitchenFeature`` reports out of the kitchen to.
public protocol KitchenFeatureHandler {
    /// The settings were asked for from the recipe list.
    @MainActor
    func kitchenFeatureDidTapSettings()

    /// A cold start found the settings open over the recipe list, and they are to open again.
    @MainActor
    func kitchenFeatureDidRestoreSettings()
}
