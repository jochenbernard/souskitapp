@testable import CookingFeature
import Foundation
import SousKit
import Testing

@Suite("Cooking feature presenter")
struct CookingFeaturePresenterTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
    }

    // Three steps, the last in a group of its own.
    private func makeStepsViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(
            recipe: parser.parseRecipe(
                """
                ## Pastry
                Rub @{125 g} butter@ into @{250 g} flour@.

                Rest the dough in the fridge for ~30 min~.

                ## Filling
                Fry @{200 g} lardons@ in a #frying pan#.
                """
            )
            .value,
            title: "Quiche Lorraine"
        )
    }

    @MainActor
    private func makePresenter(
        viewModel: CookingFeatureViewModel,
        handler: CookingFeatureHandler = CookingFeatureHandlerSpy(),
        idleTimer: IdleTimer = IdleTimerSpy(),
        timerScheduler: TimerScheduler = TimerSchedulerSpy()
    ) -> CookingFeaturePresenter {
        CookingFeaturePresenter(
            handler: handler,
            idleTimer: idleTimer,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }

    private func makeStepTimer() -> StepTimer {
        StepTimer(
            stepNumber: 3,
            text: "15 min",
            duration: .seconds(900)
        )
    }

    private func makeRunningTimer(isRinging: Bool = false) -> RunningTimer {
        RunningTimer(
            id: UUID(),
            stepTimer: makeStepTimer(),
            endDate: .now.addingTimeInterval(900.0),
            isRinging: isRinging
        )
    }

    @MainActor
    @Test("the screen stays on while the view is on screen")
    func screenStaysOn() async {
        let idleTimer = IdleTimerSpy()

        await makePresenter(viewModel: makeViewModel(), idleTimer: idleTimer).viewDidAppear()

        #expect(idleTimer.settings == [true])
    }

    @MainActor
    @Test("the screen dims again once the view leaves")
    func screenDimsAgain() async {
        let idleTimer = IdleTimerSpy()
        let presenter = makePresenter(viewModel: makeViewModel(), idleTimer: idleTimer)

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

        makePresenter(viewModel: viewModel, handler: handler).didTapExit()

        #expect(viewModel.isConfirmingExit)
        #expect(handler.exitCount == 0)
    }

    @MainActor
    @Test("confirming closes the confirmation and reports the exit")
    func confirmingReportsTheExit() {
        let viewModel = makeViewModel()
        let handler = CookingFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

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
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapExit()
        presenter.didChangeIsConfirmingExit(false)

        #expect(!viewModel.isConfirmingExit)
        #expect(handler.exitCount == 0)
    }

    @MainActor
    @Test("the first step is the current one before any is done")
    func firstStepStartsCurrent() {
        let viewModel = makeStepsViewModel()

        #expect(viewModel.progress(ofStep: 1) == .current)
        #expect(viewModel.progress(ofStep: 2) == .upcoming)
        #expect(viewModel.progress(ofStep: 3) == .upcoming)
    }

    @MainActor
    @Test("ticking off the current step makes the next one current")
    func tickingOffMovesTheCurrentStep() {
        let viewModel = makeStepsViewModel()

        makePresenter(viewModel: viewModel).didToggleStep(1)

        #expect(viewModel.progress(ofStep: 1) == .done)
        #expect(viewModel.progress(ofStep: 2) == .current)
        #expect(viewModel.progress(ofStep: 3) == .upcoming)
    }

    @MainActor
    @Test("a step ticked off ahead leaves the first one not done current")
    func tickingOffAheadKeepsTheCurrentStep() {
        let viewModel = makeStepsViewModel()

        makePresenter(viewModel: viewModel).didToggleStep(2)

        #expect(viewModel.progress(ofStep: 1) == .current)
        #expect(viewModel.progress(ofStep: 2) == .done)
        #expect(viewModel.progress(ofStep: 3) == .upcoming)
    }

    @MainActor
    @Test("ticking off a step again undoes it")
    func tickingOffAgainUndoes() {
        let viewModel = makeStepsViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didToggleStep(1)
        presenter.didToggleStep(2)
        presenter.didToggleStep(1)

        #expect(viewModel.progress(ofStep: 1) == .current)
        #expect(viewModel.progress(ofStep: 2) == .done)
    }

    @MainActor
    @Test("the steps count on across the groups")
    func stepsCountOnAcrossGroups() {
        let viewModel = makeStepsViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didToggleStep(1)
        presenter.didToggleStep(2)

        #expect(viewModel.progress(ofStep: 3) == .current)
    }

    @MainActor
    @Test("no step is current once every step is done")
    func noStepIsCurrentOnceAllAreDone() {
        let viewModel = makeStepsViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        for number in 1...3 {
            presenter.didToggleStep(number)
        }

        #expect((1...3).allSatisfy({ viewModel.progress(ofStep: $0) == .done }))
    }

    @MainActor
    @Test("the running timers arrive while the view is on screen")
    func runningTimersArrive() async {
        let viewModel = makeViewModel()
        let runningTimer = makeRunningTimer()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[], [runningTimer]])

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.runningTimers == [runningTimer])
    }

    @MainActor
    @Test("tapping a timer starts it and counts it, for the view to confirm")
    func tappingATimerStartsIt() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).didTapTimer(makeStepTimer())

        #expect(timerScheduler.startedTimers == [makeStepTimer()])
        #expect(viewModel.startedTimerCount == 1)
    }

    @MainActor
    @Test("tapping a timer without timers allowed asks to allow them")
    func tappingATimerAsksToAllowTimers() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(startError: TimerSchedulerError.notAuthorized)

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).didTapTimer(makeStepTimer())

        #expect(viewModel.isAskingToAllowTimers)
        #expect(viewModel.startedTimerCount == 0)
    }

    @MainActor
    @Test("dismissing the request to allow timers closes it")
    func dismissingTheTimersRequest() {
        let viewModel = makeViewModel()
        viewModel.isAskingToAllowTimers = true

        makePresenter(viewModel: viewModel).didChangeIsAskingToAllowTimers(false)

        #expect(!viewModel.isAskingToAllowTimers)
    }

    @MainActor
    @Test("tapping cancel on a running timer asks to confirm and cancels nothing yet")
    func tappingCancelAsksToConfirm() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = makeRunningTimer()

        makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).didTapCancelTimer(runningTimer)

        #expect(viewModel.timerConfirmingCancel == runningTimer)
        #expect(timerScheduler.cancelledTimers.isEmpty)
    }

    @MainActor
    @Test("confirming the cancel closes the confirmation and cancels the timer")
    func confirmingTheCancel() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = makePresenter(viewModel: viewModel, timerScheduler: timerScheduler)
        let runningTimer = makeRunningTimer()

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
        let presenter = makePresenter(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapCancelTimer(makeRunningTimer())
        presenter.didChangeIsConfirmingCancelTimer(false)

        #expect(viewModel.timerConfirmingCancel == nil)
        #expect(timerScheduler.cancelledTimers.isEmpty)
    }

    @MainActor
    @Test("tapping stop on a ringing timer silences it without asking")
    func stoppingARingingTimer() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = makeRunningTimer(isRinging: true)

        makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).didTapCancelTimer(runningTimer)

        #expect(viewModel.timerConfirmingCancel == nil)
        #expect(timerScheduler.cancelledTimers == [runningTimer])
    }

    @MainActor
    @Test("swiping a running timer away cancels it without asking")
    func swipingATimerAway() {
        let timerScheduler = TimerSchedulerSpy()
        let runningTimer = makeRunningTimer()

        makePresenter(viewModel: makeViewModel(), timerScheduler: timerScheduler).didSwipeAwayTimer(runningTimer)

        #expect(timerScheduler.cancelledTimers == [runningTimer])
    }

    @MainActor
    @Test("a timer that goes off while its cancel is being confirmed closes the confirmation")
    func timerGoingOffClosesTheConfirmation() async {
        let viewModel = makeViewModel()
        let runningTimer = makeRunningTimer()
        let ringingTimer = RunningTimer(
            id: runningTimer.id,
            stepTimer: runningTimer.stepTimer,
            endDate: runningTimer.endDate,
            isRinging: true
        )
        viewModel.timerConfirmingCancel = runningTimer
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[ringingTimer]])

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.timerConfirmingCancel == nil)
    }

    @MainActor
    @Test("the list of timers starts out closed")
    func timerListStartsClosed() {
        #expect(!makeViewModel().isTimerListOpen)
    }

    @MainActor
    @Test("opening the stack of timers opens the list")
    func openingTheStackOpensTheList() {
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didOpenTimerList()

        #expect(viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("closing the list folds it back into the stack")
    func closingTheList() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didOpenTimerList()
        presenter.didCloseTimerList()

        #expect(!viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("the list closes once no timer is left in it")
    func listClosesOnceEmpty() async {
        let viewModel = makeViewModel()
        viewModel.isTimerListOpen = true
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[makeRunningTimer()], []])

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(!viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("the list stays open while a timer is left in it")
    func listStaysOpenWithATimer() async {
        let viewModel = makeViewModel()
        viewModel.isTimerListOpen = true
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[makeRunningTimer()]])

        await makePresenter(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("confirming the exit cancels every running timer")
    func confirmingTheExitCancelsTheTimers() async {
        let viewModel = makeViewModel()
        let runningTimer = makeRunningTimer()
        let ringingTimer = makeRunningTimer(isRinging: true)
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[runningTimer, ringingTimer]])
        let presenter = makePresenter(viewModel: viewModel, timerScheduler: timerScheduler)

        await presenter.viewDidAppear()
        presenter.didTapExit()
        presenter.didConfirmExit()

        #expect(timerScheduler.cancelledTimers == [runningTimer, ringingTimer])
    }

    @MainActor
    @Test("dismissing the exit leaves the timers running")
    func dismissingTheExitKeepsTheTimers() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[makeRunningTimer()]])
        let presenter = makePresenter(viewModel: viewModel, timerScheduler: timerScheduler)

        await presenter.viewDidAppear()
        presenter.didTapExit()
        presenter.didChangeIsConfirmingExit(false)

        #expect(timerScheduler.cancelledTimers.isEmpty)
    }
}
