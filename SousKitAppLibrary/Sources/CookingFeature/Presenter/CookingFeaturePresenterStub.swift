struct CookingFeaturePresenterStub: CookingFeaturePresenterProtocol {
    func viewDidAppear() {}

    func viewDidDisappear() {}

    func didToggleStep(_: Int) {}

    func didTapTimer(_: StepTimer) {}

    func didOpenTimerList() {}

    func didCloseTimerList() {}

    func didTapCancelTimer(_: RunningTimer) {}

    func didSwipeAwayTimer(_: RunningTimer) {}

    func didChangeIsConfirmingCancelTimer(_: Bool) {}

    func didConfirmCancelTimer() {}

    func didChangeIsAskingToAllowTimers(_: Bool) {}

    func didTapExit() {}

    func didChangeIsConfirmingExit(_: Bool) {}

    func didConfirmExit() {}
}
