@testable import CookingFeature
import SousKit
import Testing

@Suite("New timer")
struct NewTimerTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
    }

    @MainActor
    @Test("the new timer sheet starts out closed")
    func sheetStartsClosed() {
        #expect(!makeViewModel().isAddingTimer)
    }

    @MainActor
    @Test("tapping new timer opens the sheet on an empty entry, whatever the last one held")
    func tappingNewTimerOpensTheSheet() {
        let viewModel = makeViewModel()
        viewModel.newTimer = NewTimerEntry(text: "8", unit: .hours)

        CookingFeaturePresenter.stubbed(viewModel: viewModel).didTapNewTimer()

        #expect(viewModel.isAddingTimer)
        #expect(viewModel.newTimer == NewTimerEntry())
    }

    @MainActor
    @Test("typing, stepping and choosing a unit change the entry")
    func enteringALength() {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didTapNewTimer()
        presenter.didChangeNewTimerText("44")
        presenter.didStepNewTimer(by: 1.0)
        presenter.didTapNewTimerUnit(.seconds)

        #expect(viewModel.newTimer == NewTimerEntry(text: "45", unit: .seconds))
    }

    @MainActor
    @Test("cancelling closes the sheet and starts nothing")
    func cancelling() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapNewTimer()
        presenter.didChangeNewTimerText("8")
        presenter.didChangeIsAddingTimer(false)

        #expect(!viewModel.isAddingTimer)
        #expect(timerScheduler.startedTimers.isEmpty)
        #expect(viewModel.startedTimerCount == 0)
    }

    @MainActor
    @Test("starting closes the sheet, starts a custom timer of the entered length and counts it")
    func starting() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapNewTimer()
        presenter.didChangeNewTimerText("1,5")
        await presenter.didTapStartNewTimer()

        #expect(!viewModel.isAddingTimer)
        #expect(timerScheduler.startedTimers == [.custom(.seconds(90))])
        #expect(viewModel.startedTimerCount == 1)
    }

    @MainActor
    @Test("starting with no length entered starts nothing and leaves the sheet open")
    func startingWithNoLength() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapNewTimer()
        await presenter.didTapStartNewTimer()

        #expect(viewModel.isAddingTimer)
        #expect(timerScheduler.startedTimers.isEmpty)
    }

    @MainActor
    @Test("starting without timers allowed closes the sheet and asks to allow them")
    func startingAsksToAllowTimers() async {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy(startError: TimerSchedulerError.notAuthorized)
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapNewTimer()
        presenter.didChangeNewTimerText("8")
        await presenter.didTapStartNewTimer()

        #expect(!viewModel.isAddingTimer)
        #expect(viewModel.isAskingToAllowTimers)
        #expect(viewModel.startedTimerCount == 0)
    }
}
