@testable import AppFeature
@testable import CookingFeature
import FileRecipeLibrary
import Foundation
@testable import KitchenFeature
import RecipeLibrary
import Testing

extension AppFeaturePresenterTests {
    private var runningTimer: RunningTimer {
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(
                stepNumber: 1,
                text: "2 min",
                duration: .seconds(120)
            ),
            endDate: .now.addingTimeInterval(120.0),
            isRinging: false
        )
    }

    private var cookingRestoration: AppRestoration {
        AppRestoration(
            kitchen: KitchenFeatureRestoration(recipeID: "crepes", cooking: CookingFeatureRestoration())
        )
    }

    /// Keeps a restoration as an app on the mock recipes left it.
    private func keep(_ restoration: AppRestoration) {
        recipeRepositoryKindStore.remember(.mock)
        restorationStore.update({ $0 = restoration })
    }

    @Test("what the kitchen reports open is kept, and forgotten once it reports nothing open")
    func kitchenReportIsKept() {
        let presenter = launch()
        presenter.onboardingFeatureDidChooseMockRecipes()

        presenter.kitchenFeatureDidChangeRestoration(crepesRestoration.kitchen)

        #expect(restorationStore.restoration() == crepesRestoration)

        presenter.kitchenFeatureDidChangeRestoration(nil)

        #expect(restorationStore.record() == nil)
    }

    @Test("a cold start keeps what the app had open for the kitchen to open again, in use now and unsettled")
    func coldStartKeepsWhatWasOpen() throws {
        keep(cookingRestoration)
        let before = Date.now

        _ = launch()

        let record = try #require(restorationStore.record())
        #expect(record.restoration == cookingRestoration)
        #expect(record.isSettling)
        #expect(record.lastUse >= before)
    }

    @Test("an app quit while it ran opens on its recipe list and forgets what it had open")
    func coldStartAfterTermination() {
        keep(cookingRestoration)
        restorationStore.recordTermination()

        _ = launch()

        #expect(restorationStore.record() == nil)
    }

    @Test("a timer still running opens what the app had open again, even after the app was quit")
    func runningTimerOutlivesTermination() {
        keep(cookingRestoration)
        restorationStore.recordTermination()

        _ = launch(timers: [runningTimer])

        #expect(restorationStore.restoration() == cookingRestoration)
    }

    @Test("a restore that never settled is not opened again, even with a timer running")
    func unsettledRestoreIsDropped() {
        keep(cookingRestoration)
        restorationStore.beginSettling()

        let presenter = launch(timers: [runningTimer])

        #expect(restorationStore.record() == nil)
        #expect(presenter.viewModel?.openSettings == nil)
    }

    @Test("a restore stays unsettled until the kitchen has opened it, and settles once that has been up for a while")
    func restoreSettlesAfterTheKitchenOpensIt() async {
        keep(cookingRestoration)
        let presenter = launch()

        await Task.yield()

        #expect(restorationStore.record()?.isSettling == true)

        presenter.kitchenFeatureDidRestore()

        // Waits for the settle, or for the suite's time limit to end the test.
        while restorationStore.record()?.isSettling == true {
            await Task.yield()
        }

        #expect(restorationStore.restoration() == cookingRestoration)
    }

    @Test("a restore the kitchen opened stays unsettled until it has been up for a while")
    func restoreSettlesLater() async {
        keep(cookingRestoration)
        let presenter = launch(restorationSettleTime: .seconds(60))

        presenter.kitchenFeatureDidRestore()
        await Task.yield()

        #expect(restorationStore.record()?.isSettling == true)
    }

    @Test("the settings a cold start finds open open again as restored, and settle")
    func coldStartOpensTheSettings() async {
        keep(settingsRestoration)

        let presenter = launch()

        #expect(presenter.viewModel?.openSettings?.isRestored == true)

        while restorationStore.record()?.isSettling == true {
            await Task.yield()
        }

        #expect(restorationStore.restoration() == settingsRestoration)
    }

    @Test("the settings an app quit while it ran had open stay shut")
    func settingsStayShutAfterTermination() {
        keep(settingsRestoration)
        restorationStore.recordTermination()

        #expect(launch().viewModel?.openSettings == nil)
        #expect(restorationStore.record() == nil)
    }

    @Test("a kitchen put under the open settings is handed nothing to open again")
    func kitchenUnderTheSettingsOpensOnItsList() throws {
        let presenter = launch()
        presenter.onboardingFeatureDidChooseMockRecipes()

        presenter.didTapSettings()
        presenter.settingsFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )

        #expect(restorationStore.restoration() == settingsRestoration)
        #expect(restorationStore.record()?.isSettling == false)
    }

    @Test("leaving the foreground marks the app in use now")
    func backgroundMarksUse() throws {
        keep(crepesRestoration)
        let presenter = launch()
        let before = Date.now

        presenter.didEnterBackground()

        #expect(try #require(restorationStore.record()).lastUse >= before)
    }

    @Test("a change keeps a restore unsettled, and forgets that the app was quit")
    func changeKeepsSettlingAndForgetsTermination() throws {
        restorationStore.update({ $0 = crepesRestoration })
        restorationStore.beginSettling()
        restorationStore.recordTermination()

        restorationStore.update({ $0.kitchen?.cooking = CookingFeatureRestoration() })

        let record = try #require(restorationStore.record())
        #expect(record.restoration == cookingRestoration)
        #expect(record.isSettling)
        #expect(!record.isTerminated)
    }

    @Test("the store keeps what it is given across instances, and nothing once nothing is open")
    func storeRoundTrip() {
        restorationStore.update({ $0 = cookingRestoration })

        #expect(restorationStore.restoration() == cookingRestoration)

        restorationStore.update({ $0.kitchen = nil })

        #expect(restorationStore.record() == nil)
    }
}
