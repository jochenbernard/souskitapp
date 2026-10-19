/// What ``KitchenFeature`` and ``KitchenFeatureView`` report to.
protocol KitchenFeaturePresenterProtocol {
    /// The stack the kitchen's screens are pushed on is on screen, and the call is cancelled when it leaves.
    @MainActor
    func stackDidAppear() async

    /// The app came back to the foreground.
    @MainActor
    func didBecomeActive() async

    /// A row on a screen of the kitchen was pressed.
    ///
    /// - Parameters:
    ///   - screen: The screen the row pushes.
    ///   - origin: The screen the row is on, or `nil` for the kitchen's own.
    @MainActor
    func didPush(_ screen: KitchenScreen, from origin: KitchenScreen?)

    /// The stack popped screens.
    ///
    /// - Parameter count: How many screens are left on it.
    @MainActor
    func didPop(toCount count: Int)

    /// The text searched for changed.
    ///
    /// - Parameter text: The text, which may be empty.
    @MainActor
    func didChangeSearchText(_ text: String)

    @MainActor
    func didDismissCooking()
}
