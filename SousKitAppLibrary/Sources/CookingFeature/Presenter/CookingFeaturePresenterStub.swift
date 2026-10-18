struct CookingFeaturePresenterStub: CookingFeaturePresenterProtocol {
    func viewDidAppear() {}

    func viewDidDisappear() {}

    func didToggleStep(_: Int) {}

    func didTapTimer(_: StepTimer) {}

    func didTapNewTimer() {}

    func didChangeIsAddingTimer(_: Bool) {}

    func didTapNewTimerDigits(_: String) {}

    func didTapDeleteNewTimerDigit() {}

    func didTapStartNewTimer() {}

    func didOpenTimerList() {}

    func didCloseTimerList() {}

    func didFoldTimers() {}

    func didTapCancelTimer(_: RunningTimer) {}

    func didSwipeAwayTimer(_: RunningTimer) {}

    func didKeepTimer() {}

    func didConfirmCancelTimer() {}

    func didChangeIsAskingToAllowTimers(_: Bool) {}

    func didTapExit() {}

    func didChangeIsConfirmingExit(_: Bool) {}

    func didConfirmExit() {}
}
