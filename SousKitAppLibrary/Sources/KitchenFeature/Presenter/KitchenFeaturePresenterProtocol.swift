/// What ``KitchenFeatureView`` reports to.
protocol KitchenFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    /// The app came back to the foreground.
    @MainActor
    func didBecomeActive() async

    @MainActor
    func didChangeScreenPath(_ screenPath: [KitchenScreen])

    @MainActor
    func didTapReset()

    @MainActor
    func didChangeIsConfirmingReset(_ isConfirming: Bool)

    @MainActor
    func didConfirmReset()
}
