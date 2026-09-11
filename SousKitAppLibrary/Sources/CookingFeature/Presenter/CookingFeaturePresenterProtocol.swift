/// What ``CookingFeatureView`` reports to.
protocol CookingFeaturePresenterProtocol {
    /// The view came on screen, which keeps the screen from dimming.
    @MainActor
    func viewDidAppear()

    /// The view left the screen, which lets the screen dim again.
    @MainActor
    func viewDidDisappear()

    /// The exit button was tapped, which opens the confirmation.
    @MainActor
    func didTapExit()

    /// The confirmation opened or closed.
    @MainActor
    func didChangeIsConfirmingExit(_ isConfirming: Bool)

    /// The confirmation was accepted.
    @MainActor
    func didConfirmExit()
}
