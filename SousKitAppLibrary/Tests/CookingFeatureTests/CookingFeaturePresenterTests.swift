@testable import CookingFeature
import SousKit
import Testing

@Suite("Cooking feature presenter")
struct CookingFeaturePresenterTests {
    private let parser = SousParser()

    private func makeViewModel() -> CookingFeatureViewModel {
        CookingFeatureViewModel(recipe: parser.parseRecipe("Whisk it.").value)
    }

    @MainActor
    private func makePresenter(
        viewModel: CookingFeatureViewModel,
        handler: CookingFeatureHandler = CookingFeatureHandlerSpy(),
        idleTimer: IdleTimer = IdleTimerSpy()
    ) -> CookingFeaturePresenter {
        CookingFeaturePresenter(
            handler: handler,
            idleTimer: idleTimer,
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("the screen stays on while the view is on screen")
    func screenStaysOn() {
        let idleTimer = IdleTimerSpy()

        makePresenter(viewModel: makeViewModel(), idleTimer: idleTimer).viewDidAppear()

        #expect(idleTimer.settings == [true])
    }

    @MainActor
    @Test("the screen dims again once the view leaves")
    func screenDimsAgain() {
        let idleTimer = IdleTimerSpy()
        let presenter = makePresenter(viewModel: makeViewModel(), idleTimer: idleTimer)

        presenter.viewDidAppear()
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
}
