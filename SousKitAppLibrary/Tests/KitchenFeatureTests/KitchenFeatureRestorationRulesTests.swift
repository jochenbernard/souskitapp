@testable import CookingFeature
import Foundation
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature restoration rules", .timeLimit(.minutes(1)))
struct KitchenFeatureRestorationRulesTests {
    private let parser = SousParser()
    private let defaults: ThrowawayDefaults

    private let crepes = RecipeEntry(
        id: "crepes",
        name: "crepes",
        availability: .notDownloaded
    )

    private let runningTimer = RunningTimer(
        id: UUID(),
        stepTimer: StepTimer(
            stepNumber: 1,
            text: "2 min",
            duration: .seconds(120)
        ),
        endDate: .now.addingTimeInterval(120.0),
        isRinging: false
    )

    @MainActor
    private var restorationStore: KitchenRestorationStore {
        KitchenRestorationStore(userDefaults: defaults.userDefaults)
    }

    @MainActor
    init() throws {
        self.defaults = try ThrowawayDefaults()
    }

    @MainActor
    private func makeViewModel(isRestoring: Bool = false) -> KitchenFeatureViewModel {
        let viewModel = KitchenFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .files
        )
        viewModel.isRestoring = isRestoring

        return viewModel
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        recipeRepository: RecipeRepositorySpy = RecipeRepositorySpy(),
        timerScheduler: TimerSchedulerStub = TimerSchedulerStub(),
        restorationSettleTime: Duration = .zero
    ) -> KitchenFeaturePresenter {
        KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: timerScheduler
            ),
            handler: KitchenFeatureHandlerStub(),
            recipeFeatureFactory: RecipeFeatureFactory(parser: parser, recipeRepository: recipeRepository),
            recipeRepository: recipeRepository,
            restorationSettleTime: restorationSettleTime,
            restorationStore: restorationStore,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }

    /// Restores a kitchen whose repository lists crepes, and returns its view model.
    @MainActor
    private func restoreListingCrepes(
        timerScheduler: TimerSchedulerStub = TimerSchedulerStub(),
        restorationSettleTime: Duration = .zero
    ) async -> KitchenFeatureViewModel {
        let recipeRepository = RecipeRepositorySpy()
        let viewModel = makeViewModel(isRestoring: true)
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeRepository: recipeRepository,
            timerScheduler: timerScheduler,
            restorationSettleTime: restorationSettleTime
        )

        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await presenter.viewDidAppear()

        return viewModel
    }

    @MainActor
    @Test("a kitchen quit while it ran stays on its recipe list and forgets the recipe")
    func restoreAfterTermination() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))
        restorationStore.recordTermination()

        let viewModel = await restoreListingCrepes()

        #expect(viewModel.screenPath.isEmpty)
        #expect(!viewModel.isRestoring)
        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("a timer still running opens the recipe again, even after the app was quit")
    func runningTimerOutlivesTermination() async {
        let restoration = KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration())
        restorationStore.save(restoration)
        restorationStore.recordTermination()

        let viewModel = await restoreListingCrepes(timerScheduler: TimerSchedulerStub(timers: [runningTimer]))

        #expect(viewModel.screenPath == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
        #expect(restorationStore.restoration() == restoration)
    }

    @MainActor
    @Test("a restore that never settled is not opened again, even with a timer running")
    func unsettledRestoreIsDropped() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))
        restorationStore.beginRestoring()

        let viewModel = await restoreListingCrepes(timerScheduler: TimerSchedulerStub(timers: [runningTimer]))

        #expect(viewModel.screenPath.isEmpty)
        #expect(restorationStore.restoration() == nil)
    }

    @MainActor
    @Test("a restore marks the kitchen in use now, and unsettled until it has been up for a while")
    func restoreSettlesLater() async throws {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))
        let before = Date.now

        _ = await restoreListingCrepes(restorationSettleTime: .seconds(60))

        let record = try #require(restorationStore.record())
        #expect(record.isRestoring)
        #expect(record.lastUse >= before)
    }

    @MainActor
    @Test("a restore settles once the restored kitchen has been up for a while")
    func restoreSettles() async {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))

        _ = await restoreListingCrepes()

        // Waits for the settle, or for the suite's time limit to end the test.
        while restorationStore.record()?.isRestoring == true {
            await Task.yield()
        }

        #expect(restorationStore.record()?.isRestoring == false)
    }

    @MainActor
    @Test("leaving the foreground marks the kitchen in use now")
    func backgroundMarksUse() throws {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))
        let before = Date.now

        makePresenter(viewModel: makeViewModel()).didEnterBackground()

        #expect(try #require(restorationStore.record()).lastUse >= before)
    }

    @MainActor
    @Test("a change keeps a restore unsettled, and forgets that the app was quit")
    func changeKeepsRestoringAndForgetsTermination() throws {
        restorationStore.save(KitchenRestoration(recipeID: crepes.id))
        restorationStore.beginRestoring()
        restorationStore.recordTermination()

        restorationStore.save(KitchenRestoration(recipeID: crepes.id, cooking: CookingFeatureRestoration()))

        let record = try #require(restorationStore.record())
        #expect(record.isRestoring)
        #expect(!record.isTerminated)
    }
}
