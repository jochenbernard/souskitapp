@testable import CookingFeature
import SousKit
import Testing

@Suite("Step completion")
struct StepCompletionTests {
    private let parser = SousParser()

    // Three steps, the last alone in a second group.
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
        restoration: CookingFeatureRestoration? = nil
    ) -> CookingFeaturePresenter {
        CookingFeaturePresenter(
            handler: handler,
            idleTimer: IdleTimerSpy(),
            restoration: restoration,
            timerScheduler: TimerSchedulerSpy(),
            viewModel: viewModel
        )
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
    @Test("every tick and untick reports the steps done, for a cold start")
    func tickingReportsTheRestoration() {
        let handler = CookingFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: makeStepsViewModel(), handler: handler)

        presenter.didToggleStep(1)
        presenter.didToggleStep(3)
        presenter.didToggleStep(1)

        #expect(
            handler.restorations == [
                CookingFeatureRestoration(completedStepNumbers: [1]),
                CookingFeatureRestoration(completedStepNumbers: [1, 3]),
                CookingFeatureRestoration(completedStepNumbers: [3])
            ]
        )
    }

    @MainActor
    @Test("a restored screen opens with the steps done that were done when it was left")
    func restorationTicksOffItsSteps() {
        let viewModel = makeStepsViewModel()

        _ = makePresenter(
            viewModel: viewModel,
            restoration: CookingFeatureRestoration(completedStepNumbers: [1, 2])
        )

        #expect(viewModel.progress(ofStep: 1) == .done)
        #expect(viewModel.progress(ofStep: 2) == .done)
        #expect(viewModel.progress(ofStep: 3) == .current)
    }
}
