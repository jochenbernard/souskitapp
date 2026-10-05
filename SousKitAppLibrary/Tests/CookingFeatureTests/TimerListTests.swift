@testable import CookingFeature
import Foundation
import SousKit
import Testing

@Suite("Timer list")
struct TimerListTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
    }

    @MainActor
    private func makePresenter(
        viewModel: CookingFeatureViewModel,
        timerScheduler: TimerScheduler = TimerSchedulerSpy()
    ) -> CookingFeaturePresenter {
        CookingFeaturePresenter(
            handler: CookingFeatureHandlerSpy(),
            idleTimer: IdleTimerSpy(),
            restoration: nil,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }

    private func makeRunningTimer() -> RunningTimer {
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(
                stepNumber: 3,
                text: "15 min",
                duration: .seconds(900)
            ),
            endDate: .now.addingTimeInterval(900.0),
            isRinging: false
        )
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
}
