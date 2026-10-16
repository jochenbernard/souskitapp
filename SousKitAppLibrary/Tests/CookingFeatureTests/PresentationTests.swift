@testable import CookingFeature
import SousKit
import Testing

@Suite("One presentation at a time")
struct PresentationTests {
    /// What the cooking screen opens over itself.
    enum Presentation: CaseIterable {
        case exitConfirmation
        case newTimerSheet
        case cancelConfirmation
        case timersRequest
    }

    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value, title: "Vinaigrette")
    }

    /// A presenter whose timers are not allowed, so starting one asks to allow them.
    @MainActor
    private func makePresenter(viewModel: CookingFeatureViewModel) -> CookingFeaturePresenter {
        CookingFeaturePresenter.stubbed(
            viewModel: viewModel,
            timerScheduler: TimerSchedulerSpy(startError: TimerSchedulerError.notAuthorized)
        )
    }

    @MainActor
    private func open(_ presentation: Presentation, with presenter: CookingFeaturePresenter) async {
        switch presentation {
        case .exitConfirmation: presenter.didTapExit()
        case .newTimerSheet: presenter.didTapNewTimer()
        case .cancelConfirmation: presenter.didTapCancelTimer(RunningTimer.stubbed())
        case .timersRequest: await presenter.didTapTimer(StepTimer.stubbed())
        }
    }

    @MainActor
    private func close(_ presentation: Presentation, with presenter: CookingFeaturePresenter) {
        switch presentation {
        case .exitConfirmation: presenter.didChangeIsConfirmingExit(false)
        case .newTimerSheet: presenter.didChangeIsAddingTimer(false)
        case .cancelConfirmation: presenter.didKeepTimer()
        case .timersRequest: presenter.didChangeIsAskingToAllowTimers(false)
        }
    }

    @MainActor
    private func openPresentations(in viewModel: CookingFeatureViewModel) -> [Presentation] {
        Presentation.allCases.filter { presentation in
            switch presentation {
            case .exitConfirmation: viewModel.isConfirmingExit
            case .newTimerSheet: viewModel.isAddingTimer
            case .cancelConfirmation: viewModel.timerConfirmingCancel != nil
            case .timersRequest: viewModel.isAskingToAllowTimers
            }
        }
    }

    @MainActor
    @Test(
        "two asked for in one turn open the first alone, and the second opens once the first closed",
        arguments: Presentation.allCases,
        Presentation.allCases
    )
    func askingForTwoOpensTheFirst(first: Presentation, second: Presentation) async {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        await open(first, with: presenter)
        await open(second, with: presenter)

        #expect(openPresentations(in: viewModel) == [first])

        close(first, with: presenter)
        await open(second, with: presenter)

        #expect(openPresentations(in: viewModel) == [second])
    }

    @MainActor
    @Test("a ringing timer is silenced under something open, since that asks nothing")
    func ringingTimerIsSilencedUnderSomethingOpen() {
        let viewModel = makeViewModel()
        let timerScheduler = TimerSchedulerSpy()
        let presenter = CookingFeaturePresenter.stubbed(viewModel: viewModel, timerScheduler: timerScheduler)
        let ringingTimer = RunningTimer.stubbed(isRinging: true)

        presenter.didTapExit()
        presenter.didTapCancelTimer(ringingTimer)

        #expect(viewModel.isConfirmingExit)
        #expect(timerScheduler.cancelledTimers == [ringingTimer])
    }
}
