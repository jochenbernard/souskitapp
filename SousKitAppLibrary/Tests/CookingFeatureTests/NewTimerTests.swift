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
        viewModel.newTimer = NewTimerEntry(digits: "8")

        CookingFeaturePresenter.stubbed(viewModel: viewModel).didTapNewTimer()

        #expect(viewModel.isAddingTimer)
        #expect(viewModel.newTimer == NewTimerEntry())
    }

    @MainActor
    @Test(
        "keys type their digits after the ones typed before",
        arguments: [
            (["5", "2", "0"], "520"),
            (["4", "5"], "45"),
            (["1", "3", "00", "0"], "13000"),
            (["1", "3", "0", "0", "0", "0"], "130000")
        ]
    )
    func typing(keys: [String], digits: String) {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didTapNewTimer()

        for key in keys {
            presenter.didTapNewTimerDigits(key)
        }

        #expect(viewModel.newTimer == NewTimerEntry(digits: digits))
    }

    @MainActor
    @Test("a zero or a double zero typed first types nothing, since it adds nothing to the length")
    func leadingZeros() {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didTapNewTimer()
        presenter.didTapNewTimerDigits("0")
        presenter.didTapNewTimerDigits("00")

        #expect(viewModel.newTimer == NewTimerEntry())
    }

    @MainActor
    @Test("keys type nothing past six digits, and a double zero with one place left types one zero")
    func typingStopsAtSixDigits() {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didTapNewTimer()

        for key in ["1", "2", "3", "4", "5", "00", "7"] {
            presenter.didTapNewTimerDigits(key)
        }

        #expect(viewModel.newTimer == NewTimerEntry(digits: "123450"))
    }

    @MainActor
    @Test("delete takes off the last digit typed, and does nothing once none is left")
    func deleting() {
        let viewModel = makeViewModel()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel)

        presenter.didTapNewTimer()
        presenter.didTapNewTimerDigits("5")
        presenter.didTapNewTimerDigits("20")
        presenter.didTapDeleteNewTimerDigit()

        #expect(viewModel.newTimer == NewTimerEntry(digits: "52"))

        presenter.didTapDeleteNewTimerDigit()
        presenter.didTapDeleteNewTimerDigit()
        presenter.didTapDeleteNewTimerDigit()

        #expect(viewModel.newTimer == NewTimerEntry())
    }

    @MainActor
    @Test("cancelling closes the sheet and starts nothing")
    func cancelling() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)

        presenter.didTapNewTimer()
        presenter.didTapNewTimerDigits("8")
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
        presenter.didTapNewTimerDigits("5")
        presenter.didTapNewTimerDigits("2")
        presenter.didTapNewTimerDigits("0")
        await presenter.didTapStartNewTimer()

        #expect(!viewModel.isAddingTimer)
        #expect(timerScheduler.startedTimers == [.custom(.seconds(320))])
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
        presenter.didTapNewTimerDigits("8")
        await presenter.didTapStartNewTimer()

        #expect(!viewModel.isAddingTimer)
        #expect(viewModel.isAskingToAllowTimers)
        #expect(viewModel.startedTimerCount == 0)
    }
}
