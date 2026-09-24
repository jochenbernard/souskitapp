struct CookingFeaturePresenter: CookingFeaturePresenterProtocol {
    private let handler: CookingFeatureHandler
    private let idleTimer: IdleTimer
    private let timerScheduler: TimerScheduler
    private let viewModel: CookingFeatureViewModel

    init(
        handler: CookingFeatureHandler,
        idleTimer: IdleTimer,
        timerScheduler: TimerScheduler,
        viewModel: CookingFeatureViewModel
    ) {
        self.handler = handler
        self.idleTimer = idleTimer
        self.timerScheduler = timerScheduler
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        idleTimer.setDisabled(true)

        for await runningTimers in timerScheduler.runningTimers() {
            viewModel.runningTimers = runningTimers
            closeCancelConfirmationIfOver()
        }
    }

    func viewDidDisappear() {
        idleTimer.setDisabled(false)
    }

    func didTapTimer(_ timer: StepTimer) async {
        do {
            try await timerScheduler.start(timer)
        } catch TimerSchedulerError.notAuthorized {
            viewModel.isAskingToAllowTimers = true
        } catch {
            // Nothing starts, which the timers on screen already show.
        }
    }

    func didTapCancelTimer(_ timer: RunningTimer) {
        // A ringing timer is over, so silencing it loses nothing worth confirming.
        if timer.isRinging {
            cancel(timer)
        } else {
            viewModel.timerConfirmingCancel = timer
        }
    }

    func didChangeIsConfirmingCancelTimer(_ isConfirming: Bool) {
        if !isConfirming {
            viewModel.timerConfirmingCancel = nil
        }
    }

    func didConfirmCancelTimer() {
        guard let timer = viewModel.timerConfirmingCancel else {
            return
        }

        viewModel.timerConfirmingCancel = nil
        cancel(timer)
    }

    func didChangeIsAskingToAllowTimers(_ isAsking: Bool) {
        viewModel.isAskingToAllowTimers = isAsking
    }

    func didTapExit() {
        viewModel.isConfirmingExit = true
    }

    func didChangeIsConfirmingExit(_ isConfirming: Bool) {
        viewModel.isConfirmingExit = isConfirming
    }

    func didConfirmExit() {
        viewModel.isConfirmingExit = false
        handler.cookingFeatureDidExit()
    }

    /// Closes the cancel confirmation of a timer that went off or went away, which leaves nothing to cancel.
    @MainActor
    private func closeCancelConfirmationIfOver() {
        guard let timer = viewModel.timerConfirmingCancel else {
            return
        }

        if !viewModel.runningTimers.contains(where: { $0.id == timer.id && !$0.isRinging }) {
            viewModel.timerConfirmingCancel = nil
        }
    }

    @MainActor
    private func cancel(_ timer: RunningTimer) {
        // A timer that fails to cancel stays on screen, which shows the failure.
        try? timerScheduler.cancel(timer)
    }
}
