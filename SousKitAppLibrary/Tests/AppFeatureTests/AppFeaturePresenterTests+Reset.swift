@testable import AppFeature
import FileRecipeLibrary
import Foundation
@testable import KitchenFeature
import RecipeLibrary
import Testing

extension AppFeaturePresenterTests {
    @Test("a reset closes the settings and forgets the mock recipes and the scale along with the folder")
    func resetForgetsTheMockRecipes() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        preferredScaleStore.remember(.servings(2.0))
        let presenter = launch()

        presenter.didTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)
        presenter.settingsFeatureDidConfirmReset()

        #expect(presenter.viewModel?.screen.identity == .onboarding)
        #expect(presenter.viewModel?.openSettings == nil)
        #expect(restorationStore.record()?.restoration == nil)
        #expect(launch().viewModel?.screen.identity == .onboarding)
        #expect(preferredScaleStore.preferredScale == .asWritten)
    }

    @Test("a reset cancels every timer, and leaves the app's defaults as a fresh install has them")
    func resetLeavesNothing() throws {
        let timerScheduler = TimerSchedulerStub(timers: [runningTimer])
        let presenter = launch(timerScheduler: timerScheduler)
        presenter.onboardingFeatureDidChooseMockRecipes()
        preferredScaleStore.remember(.multiplier(1.5))
        presenter.kitchenFeatureDidChangeRestoration(KitchenFeatureRestoration(recipeID: "crepes"))
        presenter.settingsFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )

        presenter.settingsFeatureDidConfirmReset()

        #expect(timerScheduler.currentRunningTimers().isEmpty)
        #expect(userDefaults.persistentDomain(forName: suiteName)?.isEmpty ?? true)
    }
}
