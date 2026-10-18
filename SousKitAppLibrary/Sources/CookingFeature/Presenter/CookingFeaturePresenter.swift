struct CookingFeaturePresenter: CookingFeaturePresenterProtocol {
    private let handler: CookingFeatureHandler
    private let idleTimer: IdleTimer
    private let timerScheduler: TimerScheduler
    private let viewModel: CookingFeatureViewModel

    @MainActor
    init(
        handler: CookingFeatureHandler,
        idleTimer: IdleTimer,
        restoration: CookingFeatureRestoration?,
        timerScheduler: TimerScheduler,
        viewModel: CookingFeatureViewModel
    ) {
        self.handler = handler
        self.idleTimer = idleTimer
        self.timerScheduler = timerScheduler
        self.viewModel = viewModel

        // Set before the screen first draws, so neither a step already done nor a timer already running animates in.
        viewModel.completedStepNumbers = restoration?.completedStepNumbers ?? []
        viewModel.runningTimers = timerScheduler.currentRunningTimers()
    }

    func viewDidAppear() async {
        idleTimer.setDisabled(true)

        for await runningTimers in timerScheduler.runningTimers() {
            viewModel.runningTimers = runningTimers
            closeCancelConfirmationIfOver()

            if runningTimers.isEmpty {
                viewModel.isTimerListOpen = false
            }
        }
    }

    func viewDidDisappear() {
        idleTimer.setDisabled(false)
    }

    func didToggleStep(_ number: Int) {
        if viewModel.completedStepNumbers.contains(number) {
            viewModel.completedStepNumbers.remove(number)
        } else {
            viewModel.completedStepNumbers.insert(number)
        }

        handler.cookingFeatureDidChangeRestoration(
            CookingFeatureRestoration(completedStepNumbers: viewModel.completedStepNumbers)
        )
    }

    func didTapTimer(_ timer: StepTimer) async {
        await start(.step(timer))
    }

    func didTapNewTimer() {
        guard !isPresenting else {
            return
        }

        viewModel.newTimer = NewTimerEntry()
        viewModel.isAddingTimer = true
    }

    func didChangeIsAddingTimer(_ isAdding: Bool) {
        viewModel.isAddingTimer = isAdding
    }

    func didTapNewTimerDigits(_ digits: String) {
        for digit in digits where viewModel.newTimer.digits.count < NewTimerEntry.capacity {
            // A zero in front adds nothing to the length.
            if digit != "0" || !viewModel.newTimer.digits.isEmpty {
                viewModel.newTimer.digits.append(digit)
            }
        }
    }

    func didTapDeleteNewTimerDigit() {
        _ = viewModel.newTimer.digits.popLast()
    }

    func didTapStartNewTimer() async {
        guard let duration = viewModel.newTimer.duration else {
            return
        }

        viewModel.isAddingTimer = false
        await start(.custom(duration))
    }

    func didOpenTimerList() {
        viewModel.isTimerListOpen = true
    }

    func didCloseTimerList() {
        viewModel.isTimerListOpen = false
    }

    func didTapCancelTimer(_ timer: RunningTimer) {
        // A ringing timer is over, so silencing it loses nothing worth confirming.
        if timer.isRinging {
            cancel(timer)
        } else if !isPresenting {
            viewModel.timerConfirmingCancel = timer
        }
    }

    // The swipe itself is the deliberate act, so it asks nothing.
    func didSwipeAwayTimer(_ timer: RunningTimer) {
        cancel(timer)
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
        guard !isPresenting else {
            return
        }

        viewModel.isConfirmingExit = true
    }

    func didChangeIsConfirmingExit(_ isConfirming: Bool) {
        viewModel.isConfirmingExit = isConfirming
    }

    func didConfirmExit() {
        viewModel.isConfirmingExit = false

        // A timer belongs to the recipe being cooked, so leaving it stops them all.
        for timer in viewModel.runningTimers {
            cancel(timer)
        }

        handler.cookingFeatureDidExit()
    }

    /// Whether something is open over the screen, which takes one at a time: two opened together show neither.
    @MainActor
    private var isPresenting: Bool {
        viewModel.isAddingTimer
            || viewModel.isConfirmingExit
            || viewModel.isAskingToAllowTimers
            || viewModel.timerConfirmingCancel != nil
    }

    @MainActor
    private func start(_ timer: CookingTimer) async {
        do {
            try await timerScheduler.start(timer)
            viewModel.startedTimerCount += 1
        } catch TimerSchedulerError.notAuthorized {
            if !isPresenting {
                viewModel.isAskingToAllowTimers = true
            }
        } catch {
            // Nothing starts, which the timers on screen already show.
        }
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
