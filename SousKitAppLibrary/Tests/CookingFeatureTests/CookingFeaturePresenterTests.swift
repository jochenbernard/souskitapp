@testable import CookingFeature
import SousKit
import Testing

@Suite("Cooking feature presenter")
struct CookingFeaturePresenterTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
    }

    @MainActor
    @Test("the screen stays on while the view is on screen")
    func screenStaysOn() async {
        let idleTimer = IdleTimerSpy()

        await CookingFeaturePresenter.stubbed(viewModel: makeViewModel(), idleTimer: idleTimer).viewDidAppear()

        #expect(idleTimer.settings == [true])
    }

    @MainActor
    @Test("the screen dims again once the view leaves")
    func screenDimsAgain() async {
        let idleTimer = IdleTimerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: makeViewModel(), idleTimer: idleTimer)

        await presenter.viewDidAppear()
        presenter.viewDidDisappear()

        #expect(idleTimer.settings == [true, false])
    }

    @MainActor
    @Test("the confirmation starts out closed")
    func confirmationStartsClosed() {
        #expect(!makeViewModel().isConfirmingExit)
    }

    @MainActor
    @Test("tapping exit opens the confirmation and reports nothing yet")
    func tappingExitOpensTheConfirmation() {
        let viewModel = makeViewModel()
        let handler = CookingFeatureHandlerSpy()

        CookingFeaturePresenter.stubbed(viewModel: viewModel, handler: handler).didTapExit()

        #expect(viewModel.isConfirmingExit)
        #expect(handler.exitCount == 0)
    }

    @MainActor
    @Test("confirming closes the confirmation and reports the exit")
    func confirmingReportsTheExit() {
        let viewModel = makeViewModel()
        let handler = CookingFeatureHandlerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, handler: handler)

        presenter.didTapExit()
        presenter.didConfirmExit()

        #expect(!viewModel.isConfirmingExit)
        #expect(handler.exitCount == 1)
    }

    @MainActor
    @Test("dismissing the confirmation reports nothing")
    func dismissingReportsNothing() {
        let viewModel = makeViewModel()
        let handler = CookingFeatureHandlerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, handler: handler)

        presenter.didTapExit()
        presenter.didChangeIsConfirmingExit(false)

        #expect(!viewModel.isConfirmingExit)
        #expect(handler.exitCount == 0)
    }

    @MainActor
    @Test("the timers already running are there before the view first draws, so none of them animates in")
    func runningTimersAreThereBeforeTheFirstDraw() {
        let viewModel = makeViewModel()
        let runningTimer = RunningTimer.stubbed()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[runningTimer]])

        _ = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        #expect(viewModel.runningTimers == [runningTimer])
    }

    @MainActor
    @Test("the running timers arrive while the view is on screen")
    func runningTimersArrive() async {
        let viewModel = makeViewModel()
        let runningTimer = RunningTimer.stubbed()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[], [runningTimer]])

        await CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.runningTimers == [runningTimer])
    }

    @MainActor
    @Test("tapping a timer starts it and counts it, for the view to confirm")
    func tappingATimerStartsIt() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()

        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        await presenter.didTapTimer(StepTimer.stubbed())

        #expect(timerScheduler.startedTimers == [StepTimer.stubbed()])
        #expect(viewModel.startedTimerCount == 1)
    }

    @MainActor
    @Test("tapping a timer without timers allowed asks to allow them")
    func tappingATimerAsksToAllowTimers() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(startError: TimerSchedulerError.notAuthorized)

        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        await presenter.didTapTimer(StepTimer.stubbed())

        #expect(viewModel.isAskingToAllowTimers)
        #expect(viewModel.startedTimerCount == 0)
    }

    @MainActor
    @Test("dismissing the request to allow timers closes it")
    func dismissingTheTimersRequest() {
        let viewModel = makeViewModel()
        viewModel.isAskingToAllowTimers = true

        CookingFeaturePresenter.stubbed(viewModel: viewModel).didChangeIsAskingToAllowTimers(false)

        #expect(!viewModel.isAskingToAllowTimers)
    }

    @MainActor
    @Test("tapping cancel on a running timer asks to confirm and cancels nothing yet")
    func tappingCancelAsksToConfirm() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = RunningTimer.stubbed()

        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        presenter.didTapCancelTimer(runningTimer)

        #expect(viewModel.timerConfirmingCancel == runningTimer)
        #expect(timerScheduler.cancelledTimers.isEmpty)
    }

    @MainActor
    @Test("confirming the cancel closes the confirmation and cancels the timer")
    func confirmingTheCancel() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        let runningTimer = RunningTimer.stubbed()

        presenter.didTapCancelTimer(runningTimer)
        presenter.didConfirmCancelTimer()

        #expect(viewModel.timerConfirmingCancel == nil)
        #expect(timerScheduler.cancelledTimers == [runningTimer])
    }

    @MainActor
    @Test("dismissing the cancel confirmation cancels nothing")
    func dismissingTheCancel() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapCancelTimer(RunningTimer.stubbed())
        presenter.didChangeIsConfirmingCancelTimer(false)

        #expect(viewModel.timerConfirmingCancel == nil)
        #expect(timerScheduler.cancelledTimers.isEmpty)
    }

    @MainActor
    @Test("tapping stop on a ringing timer silences it without asking")
    func stoppingARingingTimer() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = RunningTimer.stubbed(isRinging: true)

        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        presenter.didTapCancelTimer(runningTimer)

        #expect(viewModel.timerConfirmingCancel == nil)
        #expect(timerScheduler.cancelledTimers == [runningTimer])
    }

    @MainActor
    @Test("swiping a running timer away cancels it without asking")
    func swipingATimerAway() {
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = RunningTimer.stubbed()

        let presenter = CookingFeaturePresenter.stubbed(viewModel: makeViewModel(), timerScheduler: timerScheduler)
        presenter.didSwipeAwayTimer(runningTimer)

        #expect(timerScheduler.cancelledTimers == [runningTimer])
    }

    @MainActor
    @Test("a timer that goes off while its cancel is being confirmed closes the confirmation")
    func timerGoingOffClosesTheConfirmation() async {
        let viewModel = makeViewModel()
        let runningTimer = RunningTimer.stubbed()
        let ringingTimer = RunningTimer(
            id: runningTimer.id,
            stepTimer: runningTimer.stepTimer,
            endDate: runningTimer.endDate,
            isRinging: true
        )
        viewModel.timerConfirmingCancel = runningTimer
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[ringingTimer]])

        await CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.timerConfirmingCancel == nil)
    }

    @MainActor
    @Test("confirming the exit cancels every running timer")
    func confirmingTheExitCancelsTheTimers() async {
        let viewModel = makeViewModel()
        let runningTimer = RunningTimer.stubbed()
        let ringingTimer = RunningTimer.stubbed(isRinging: true)
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[runningTimer, ringingTimer]])
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        await presenter.viewDidAppear()
        presenter.didTapExit()
        presenter.didConfirmExit()

        #expect(timerScheduler.cancelledTimers == [runningTimer, ringingTimer])
    }

    @MainActor
    @Test("dismissing the exit leaves the timers running")
    func dismissingTheExitKeepsTheTimers() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[RunningTimer.stubbed()]])
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        await presenter.viewDidAppear()
        presenter.didTapExit()
        presenter.didChangeIsConfirmingExit(false)

        #expect(timerScheduler.cancelledTimers.isEmpty)
    }
}
