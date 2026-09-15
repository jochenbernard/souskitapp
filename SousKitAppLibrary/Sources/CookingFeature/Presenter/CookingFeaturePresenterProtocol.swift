/// What ``CookingFeatureView`` reports to.
protocol CookingFeaturePresenterProtocol {
    @MainActor
    func viewDidAppear()

    @MainActor
    func viewDidDisappear()

    @MainActor
    func didTapExit()

    @MainActor
    func didChangeIsConfirmingExit(_ isConfirming: Bool)

    @MainActor
    func didConfirmExit()
}
