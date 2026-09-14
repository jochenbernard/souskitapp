/// What ``KitchenFeatureView`` reports to.
protocol KitchenFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    /// The app came back to the foreground.
    @MainActor
    func didBecomeActive()

    /// The screens pushed on the navigation stack changed.
    @MainActor
    func didChangeScreenPath(_ screenPath: [KitchenScreen])

    /// The debug menu's reset was tapped, which opens the confirmation.
    @MainActor
    func didTapReset()

    /// The confirmation opened or closed.
    @MainActor
    func didChangeIsConfirmingReset(_ isConfirming: Bool)

    /// The confirmation was accepted.
    @MainActor
    func didConfirmReset()
}
