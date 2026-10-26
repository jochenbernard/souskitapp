@testable import AppFeature
import CookingFeature
import FileRecipeLibrary
import Foundation
@testable import KitchenFeature
import MockRecipeLibrary
import OnboardingFeature
import RecipeLibrary
import SettingsFeature
import SousKit
import Testing

@MainActor
@Suite("App feature presenter")
final class AppFeaturePresenterTests {
    private let parser = SousParser()
    private let cachesURL: URL
    let suiteName: String
    private let symbolCacheURL: URL
    let userDefaults: UserDefaults

    let crepesRestoration = AppRestoration(kitchen: KitchenFeatureRestoration(recipeID: "crepes"))
    let settingsRestoration = AppRestoration(isShowingSettings: true)

    init() throws {
        self.suiteName = "AppFeaturePresenterTests.\(UUID().uuidString)"
        self.cachesURL = URL.temporaryDirectory.appending(path: "\(suiteName).caches")
        self.symbolCacheURL = URL.temporaryDirectory.appending(path: "\(suiteName).json")
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: cachesURL)
        try? FileManager.default.removeItem(at: symbolCacheURL)
    }

    /// A store keeping what the app has open in this suite's defaults.
    var restorationStore: AppRestorationStore {
        AppRestorationStore(userDefaults: userDefaults)
    }

    /// A store remembering the kind of repository in this suite's defaults.
    var recipeRepositoryKindStore: RecipeRepositoryKindStore {
        RecipeRepositoryKindStore(userDefaults: userDefaults)
    }

    /// A store remembering the scale recipes open on in this suite's defaults.
    var preferredScaleStore: UserDefaultsPreferredScaleStore {
        UserDefaultsPreferredScaleStore(userDefaults: userDefaults)
    }

    /// A store remembering the folder in this suite's defaults, and keeping what it reads in this suite's caches.
    func makeRecipeRepositoryStore() -> FileRecipeRepositoryStore {
        FileRecipeRepositoryStore(
            parser: parser,
            symbolPicker: RecipeSymbolPickerStub(),
            userDefaults: userDefaults,
            cachesDirectory: cachesURL
        )
    }

    /// A presenter opened on the screen the defaults call for, as a cold start opens one.
    func launch(
        timerScheduler: TimerSchedulerStub = TimerSchedulerStub(),
        restorationSettleTime: Duration = .zero
    ) -> AppFeaturePresenter {
        let recipeRepositoryStore = makeRecipeRepositoryStore()
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: KitchenFeatureFactory(
                parser: parser,
                preferredScaleStore: preferredScaleStore,
                timerScheduler: TimerSchedulerStub()
            ),
            mockRecipeRepository: MockRecipeRepository(
                parser: parser,
                symbolPicker: RecipeSymbolPickerStub(),
                symbolCacheURL: symbolCacheURL
            ),
            onboardingFeatureFactory: OnboardingFeatureFactory(recipeRepositoryStore: recipeRepositoryStore),
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore,
            restorationSettleTime: restorationSettleTime,
            restorationStore: restorationStore,
            settingsFeatureFactory: SettingsFeatureFactory(
                appVersion: AppVersion(bundle: .main),
                preferredScaleStore: preferredScaleStore,
                recipeRepositoryStore: recipeRepositoryStore
            ),
            timerScheduler: timerScheduler
        )
        _ = presenter.makeViewModel()

        return presenter
    }

    /// A presenter moved from onboarding to the kitchen on the mock recipes.
    private func launchOnMockRecipes() -> AppFeaturePresenter {
        let presenter = launch()
        presenter.onboardingFeatureDidChooseMockRecipes()

        return presenter
    }

    /// The kitchen the presenter is on and the kind of repository remembered, or `nil` off the kitchen.
    private func kitchen(of presenter: AppFeaturePresenter) -> (id: UUID, kind: RecipeRepositoryKind)? {
        switch presenter.viewModel?.screen.identity {
        case .kitchen(let id): (id, recipeRepositoryKindStore.recipeRepositoryKind)
        case .onboarding, nil: nil
        }
    }

    @Test("onboarding opens before a folder is picked")
    func onboardingBeforeAFolder() {
        #expect(launch().viewModel?.screen.identity == .onboarding)
    }

    @Test("choosing the mock recipes on onboarding opens the kitchen on them")
    func mockRecipesFromOnboarding() {
        let presenter = launch()

        presenter.onboardingFeatureDidChooseMockRecipes()

        #expect(kitchen(of: presenter)?.kind == .mock)
    }

    @Test("the next launch opens on the mock recipes once they are chosen")
    func mockRecipesAreRemembered() {
        launch().onboardingFeatureDidChooseMockRecipes()

        #expect(kitchen(of: launch())?.kind == .mock)
    }

    @Test("the settings open over the kitchen and are kept for the next cold start")
    func settingsOpen() {
        let presenter = launchOnMockRecipes()

        presenter.didTapSettings()

        #expect(presenter.viewModel?.openSettings?.isRestored == false)
        #expect(restorationStore.record()?.restoration == settingsRestoration)
    }

    @Test("the settings stay closed over a recipe the kitchen has open, and open once it is back on its list")
    func settingsStayClosedOverARecipe() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidChangeRestoration(crepesRestoration.kitchen)
        presenter.didTapSettings()

        #expect(presenter.viewModel?.openSettings == nil)
        #expect(restorationStore.record()?.restoration == crepesRestoration)

        presenter.kitchenFeatureDidChangeRestoration(nil)
        presenter.didTapSettings()

        #expect(presenter.viewModel?.openSettings != nil)
    }

    @Test("the settings open over a folder the kitchen has pushed")
    func settingsOpenOverAFolder() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidChangeRestoration(KitchenFeatureRestoration(folderPath: ["Baking"]))
        presenter.didTapSettings()

        #expect(presenter.viewModel?.openSettings != nil)
    }

    @Test("the settings open again from the list of a kitchen put under them while they were open over a recipe")
    func settingsOpenAfterAKitchenReplacesOneOnARecipe() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        restorationStore.update({ $0 = AppRestoration(kitchen: crepesRestoration.kitchen, isShowingSettings: true) })
        let presenter = launch()
        presenter.viewDidAppear()

        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(restorationStore.record()?.restoration == settingsRestoration)

        presenter.settingsFeatureDidFinish()
        presenter.didTapSettings()

        #expect(presenter.viewModel?.openSettings != nil)
    }

    @Test("the kitchen is told the settings are open over it, until they close")
    func settingsCoverTheKitchen() {
        let presenter = launchOnMockRecipes()

        #expect(!presenter.kitchenFeatureIsCovered)

        presenter.didTapSettings()

        #expect(presenter.kitchenFeatureIsCovered)

        presenter.settingsFeatureDidFinish()

        #expect(!presenter.kitchenFeatureIsCovered)
    }

    @Test("the settings close and are forgotten when they are done or dismissed")
    func settingsClose() {
        let presenter = launchOnMockRecipes()

        presenter.didTapSettings()
        presenter.settingsFeatureDidFinish()

        #expect(presenter.viewModel?.openSettings == nil)
        #expect(restorationStore.record()?.restoration == nil)

        presenter.didTapSettings()
        presenter.didDismissSettings()

        #expect(presenter.viewModel?.openSettings == nil)
        #expect(restorationStore.record()?.restoration == nil)
    }

    @Test("a sheet reporting settings already closed leaves what the kitchen opened since")
    func lateDismissalKeepsTheKitchen() {
        let presenter = launchOnMockRecipes()

        presenter.didTapSettings()
        presenter.settingsFeatureDidFinish()
        presenter.kitchenFeatureDidChangeRestoration(crepesRestoration.kitchen)
        presenter.didDismissSettings()

        #expect(restorationStore.record()?.restoration == crepesRestoration)
    }

    @Test("picking the folder in the settings before a folder is picked closes them and goes back to onboarding")
    func folderWithoutAFolderOpensOnboarding() {
        let presenter = launchOnMockRecipes()

        presenter.didTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(presenter.viewModel?.screen.identity == .onboarding)
        #expect(presenter.viewModel?.openSettings == nil)
        #expect(restorationStore.record()?.restoration == nil)
    }

    @Test("the kitchen moves between the folder picked and the mock recipes under the settings, which stay open")
    func kitchenMovesBetweenKinds() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        let presenter = launch()
        let folderKitchen = try #require(kitchen(of: presenter))

        #expect(folderKitchen.kind == .files)

        presenter.didTapSettings()
        let settingsID = try #require(presenter.viewModel?.openSettings?.id)
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)
        let mockKitchen = try #require(kitchen(of: presenter))

        #expect(mockKitchen.kind == .mock)
        #expect(mockKitchen.id != folderKitchen.id)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)
        #expect(restorationStore.record()?.restoration == settingsRestoration)

        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(kitchen(of: presenter)?.kind == .files)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)
        #expect(restorationStore.record()?.restoration == settingsRestoration)
    }

    @Test("the kind of repository already read, picked in the settings, leaves the kitchen as it is")
    func pickingTheSameKindKeepsTheKitchen() throws {
        let presenter = launchOnMockRecipes()
        let mockKitchen = try #require(kitchen(of: presenter))

        presenter.didTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(kitchen(of: presenter)?.id == mockKitchen.id)
        #expect(presenter.viewModel?.openSettings != nil)
    }

    @Test("a folder connected in the settings opens a kitchen of its own on it, over the mock recipes too")
    func folderConnectedInTheSettings() throws {
        let presenter = launchOnMockRecipes()
        let mockKitchen = try #require(kitchen(of: presenter))

        presenter.didTapSettings()
        let settingsID = try #require(presenter.viewModel?.openSettings?.id)
        presenter.settingsFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )
        let folderKitchen = try #require(kitchen(of: presenter))

        #expect(folderKitchen.kind == .files)
        #expect(folderKitchen.id != mockKitchen.id)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)

        presenter.settingsFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )

        #expect(kitchen(of: presenter)?.id != folderKitchen.id)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)
        #expect(kitchen(of: launch())?.kind == .files)
    }

    @Test("the scale picked is kept across instances, and as written once cleared")
    func preferredScaleRoundTrip() {
        #expect(preferredScaleStore.preferredScale == .asWritten)

        preferredScaleStore.remember(.multiplier(1.5))

        #expect(preferredScaleStore.preferredScale == .multiplier(1.5))

        preferredScaleStore.clear()

        #expect(preferredScaleStore.preferredScale == .asWritten)
    }

    @Test("onboarding forgets what the app had open, which belongs to a kitchen that is gone")
    func onboardingForgetsWhatWasOpen() {
        restorationStore.update({ $0 = crepesRestoration })

        #expect(launch().viewModel?.screen.identity == .onboarding)
        #expect(restorationStore.record()?.restoration == nil)
    }
}
