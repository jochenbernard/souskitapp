/// What ``CookingFeatureView`` reports to.
protocol CookingFeaturePresenterProtocol {
    @MainActor
    func viewDidAppear() async

    @MainActor
    func viewDidDisappear()

    @MainActor
    func didTapTimer(_ timer: StepTimer) async

    @MainActor
    func didOpenTimerList()

    @MainActor
    func didCloseTimerList()

    @MainActor
    func didTapCancelTimer(_ timer: RunningTimer)

    @MainActor
    func didChangeIsConfirmingCancelTimer(_ isConfirming: Bool)

    @MainActor
    func didConfirmCancelTimer()

    @MainActor
    func didChangeIsAskingToAllowTimers(_ isAsking: Bool)

    @MainActor
    func didTapExit()

    @MainActor
    func didChangeIsConfirmingExit(_ isConfirming: Bool)

    @MainActor
    func didConfirmExit()
}
