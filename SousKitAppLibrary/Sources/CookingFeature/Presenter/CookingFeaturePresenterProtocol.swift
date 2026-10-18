/// What ``CookingFeatureView`` reports to.
protocol CookingFeaturePresenterProtocol {
    @MainActor
    func viewDidAppear() async

    @MainActor
    func viewDidDisappear()

    @MainActor
    func didToggleStep(_ number: Int)

    @MainActor
    func didTapTimer(_ timer: StepTimer) async

    @MainActor
    func didTapNewTimer()

    @MainActor
    func didChangeIsAddingTimer(_ isAdding: Bool)

    @MainActor
    func didTapNewTimerDigits(_ digits: String)

    @MainActor
    func didTapDeleteNewTimerDigit()

    @MainActor
    func didTapStartNewTimer() async

    @MainActor
    func didOpenTimerList()

    @MainActor
    func didCloseTimerList()

    @MainActor
    func didFoldTimers()

    @MainActor
    func didTapCancelTimer(_ timer: RunningTimer)

    @MainActor
    func didSwipeAwayTimer(_ timer: RunningTimer)

    @MainActor
    func didKeepTimer()

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
