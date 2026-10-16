@testable import CookingFeature
import SousKit
import Testing

@Suite("Timer list")
struct TimerListTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
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

        CookingFeaturePresenter.stubbed(viewModel: viewModel).didOpenTimerList()

        #expect(viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("closing the list folds it back into the stack")
    func closingTheList() {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didOpenTimerList()
        presenter.didCloseTimerList()

        #expect(!viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("the list closes once no timer is left in it")
    func listClosesOnceEmpty() async {
        let viewModel = makeViewModel()
        viewModel.isTimerListOpen = true
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[RunningTimer.stubbed()], []])

        await CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(!viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("the list stays open while a timer is left in it")
    func listStaysOpenWithATimer() async {
        let viewModel = makeViewModel()
        viewModel.isTimerListOpen = true
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[RunningTimer.stubbed()]])

        await CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler).viewDidAppear()

        #expect(viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("folding the timers with a cancel confirmation open opens the list")
    func foldingWhileConfirmingOpensTheList() {
        let viewModel = makeViewModel()
        let timer = RunningTimer.stubbed()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[RunningTimer.stubbed(), timer]])
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapCancelTimer(timer)
        presenter.didFoldTimers()

        #expect(viewModel.isTimerListOpen)
        #expect(viewModel.timerConfirmingCancel == timer)
    }

    @MainActor
    @Test("folding the timers with no confirmation open leaves the list closed")
    func foldingLeavesTheListClosed() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[RunningTimer.stubbed(), RunningTimer.stubbed()]])

        CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler).didFoldTimers()

        #expect(!viewModel.isTimerListOpen)
    }

    @MainActor
    @Test("folding a lone timer with its cancel confirmation open leaves the list closed")
    func foldingALoneTimerLeavesTheListClosed() {
        let viewModel = makeViewModel()
        let timer = RunningTimer.stubbed()
        let timerScheduler = TimerSchedulerSpy(runningTimerUpdates: [[timer]])
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapCancelTimer(timer)
        presenter.didFoldTimers()

        #expect(!viewModel.isTimerListOpen)
    }
}
