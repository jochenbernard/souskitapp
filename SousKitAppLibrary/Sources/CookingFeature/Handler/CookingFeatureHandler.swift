/// What ``CookingFeature`` reports to.
public protocol CookingFeatureHandler {
    /// A cook confirmed leaving the cooking screen.
    @MainActor
    func cookingFeatureDidExit()

    /// What the screen has done changed, for a cold start to restore.
    ///
    /// - Parameter restoration: What the screen has done now.
    @MainActor
    func cookingFeatureDidChangeRestoration(_ restoration: CookingFeatureRestoration)
}
