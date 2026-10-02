struct CookingFeaturePresenterStub: CookingFeaturePresenterProtocol {
    func viewDidAppear() {}

    func viewDidDisappear() {}

    func didTapTimer(_: StepTimer) {}

    func didOpenTimerList() {}

    func didCloseTimerList() {}

    func didTapCancelTimer(_: RunningTimer) {}

    func didChangeIsConfirmingCancelTimer(_: Bool) {}

    func didConfirmCancelTimer() {}

    func didChangeIsAskingToAllowTimers(_: Bool) {}

    func didTapExit() {}

    func didChangeIsConfirmingExit(_: Bool) {}

    func didConfirmExit() {}
}
