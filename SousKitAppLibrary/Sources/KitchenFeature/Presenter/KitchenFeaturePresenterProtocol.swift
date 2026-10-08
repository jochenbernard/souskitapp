/// What ``KitchenFeatureView`` reports to.
protocol KitchenFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    /// The app came back to the foreground.
    @MainActor
    func didBecomeActive() async

    /// The app left the foreground.
    @MainActor
    func didEnterBackground()

    @MainActor
    func didChangeScreenPath(_ screenPath: [KitchenScreen])

    @MainActor
    func didDismissCooking()

    @MainActor
    func didTapSettings()

    @MainActor
    func didDismissSettings()

    /// The settings sheet finished sliding away.
    @MainActor
    func didFinishDismissingSettings()
}
