@testable import AppFeature
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
    private let suiteName: String
    private let userDefaults: UserDefaults

    private let crepesRestoration = KitchenRestoration(recipeID: "crepes")
    private let settingsRestoration = KitchenRestoration(recipeID: nil, isShowingSettings: true)

    init() throws {
        self.suiteName = "AppFeaturePresenterTests.\(UUID().uuidString)"
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// A store keeping what the kitchen has open in this suite's defaults.
    private var kitchenRestorationStore: KitchenRestorationStore {
        KitchenRestorationStore(userDefaults: userDefaults)
    }

    /// A store remembering the kind of repository in this suite's defaults.
    private var recipeRepositoryKindStore: RecipeRepositoryKindStore {
        RecipeRepositoryKindStore(userDefaults: userDefaults)
    }

    /// A store remembering the scale recipes open on in this suite's defaults.
    private var preferredScaleStore: UserDefaultsPreferredScaleStore {
        UserDefaultsPreferredScaleStore(userDefaults: userDefaults)
    }

    /// A store remembering the folder in this suite's defaults.
    private func makeRecipeRepositoryStore() -> FileRecipeRepositoryStore {
        FileRecipeRepositoryStore(
            parser: parser,
            userDefaults: userDefaults
        )
    }

    /// A presenter opened on the screen the defaults call for, as a launch opens one.
    private func launch() -> AppFeaturePresenter {
        let recipeRepositoryStore = makeRecipeRepositoryStore()
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: KitchenFeatureFactory(
                parser: parser,
                preferredScaleStore: preferredScaleStore,
                restorationStore: kitchenRestorationStore
            ),
            kitchenRestorationStore: kitchenRestorationStore,
            mockRecipeRepository: MockRecipeRepository(parser: parser),
            onboardingFeatureFactory: OnboardingFeatureFactory(recipeRepositoryStore: recipeRepositoryStore),
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore,
            settingsFeatureFactory: SettingsFeatureFactory(
                appVersion: AppVersion(bundle: .main),
                preferredScaleStore: preferredScaleStore,
                recipeRepositoryStore: recipeRepositoryStore
            )
        )
        presenter.viewModel = AppFeatureViewModel(screen: presenter.makeScreen())

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

        presenter.kitchenFeatureDidTapSettings()

        #expect(presenter.viewModel?.openSettings?.isRestored == false)
        #expect(kitchenRestorationStore.restoration() == settingsRestoration)
    }

    @Test("the settings a cold start opens again open as restored")
    func settingsRestored() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidRestoreSettings()

        #expect(presenter.viewModel?.openSettings?.isRestored == true)
    }

    @Test("the settings close and are forgotten when they are done or dismissed")
    func settingsClose() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidFinish()

        #expect(presenter.viewModel?.openSettings == nil)
        #expect(kitchenRestorationStore.restoration() == nil)

        presenter.kitchenFeatureDidTapSettings()
        presenter.didDismissSettings()

        #expect(presenter.viewModel?.openSettings == nil)
        #expect(kitchenRestorationStore.restoration() == nil)
    }

    @Test("a sheet reporting settings already closed leaves what the kitchen opened since")
    func lateDismissalKeepsTheKitchen() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidFinish()
        kitchenRestorationStore.save(crepesRestoration)
        presenter.didDismissSettings()

        #expect(kitchenRestorationStore.restoration() == crepesRestoration)
    }

    @Test("picking the folder in the settings before a folder is picked closes them and goes back to onboarding")
    func folderWithoutAFolderOpensOnboarding() {
        let presenter = launchOnMockRecipes()

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(presenter.viewModel?.screen.identity == .onboarding)
        #expect(presenter.viewModel?.openSettings == nil)
        #expect(kitchenRestorationStore.restoration() == nil)
    }

    @Test("the kitchen moves between the folder picked and the mock recipes under the settings, which stay open")
    func kitchenMovesBetweenKinds() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        let presenter = launch()
        let folderKitchen = try #require(kitchen(of: presenter))

        #expect(folderKitchen.kind == .files)

        presenter.kitchenFeatureDidTapSettings()
        let settingsID = try #require(presenter.viewModel?.openSettings?.id)
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)
        let mockKitchen = try #require(kitchen(of: presenter))

        #expect(mockKitchen.kind == .mock)
        #expect(mockKitchen.id != folderKitchen.id)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)
        #expect(kitchenRestorationStore.restoration() == settingsRestoration)

        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(kitchen(of: presenter)?.kind == .files)
        #expect(presenter.viewModel?.openSettings?.id == settingsID)
        #expect(kitchenRestorationStore.restoration() == settingsRestoration)
    }

    @Test("the kind of repository already read, picked in the settings, leaves the kitchen as it is")
    func pickingTheSameKindKeepsTheKitchen() throws {
        let presenter = launchOnMockRecipes()
        let mockKitchen = try #require(kitchen(of: presenter))

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(kitchen(of: presenter)?.id == mockKitchen.id)
        #expect(presenter.viewModel?.openSettings != nil)
    }

    @Test("a kitchen put under the open settings opens on its recipe list, not as a cold start")
    func kitchenUnderTheSettingsIsNotRestored() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        let presenter = launch()

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)

        // A kitchen restoring would report the settings it found kept, as restored.
        #expect(presenter.viewModel?.openSettings?.isRestored == false)
        #expect(kitchenRestorationStore.record()?.isSettling == false)
    }

    @Test("a folder connected in the settings opens a kitchen of its own on it, over the mock recipes too")
    func folderConnectedInTheSettings() throws {
        let presenter = launchOnMockRecipes()
        let mockKitchen = try #require(kitchen(of: presenter))

        presenter.kitchenFeatureDidTapSettings()
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

    @Test("a reset closes the settings and forgets the mock recipes and the scale along with the folder")
    func resetForgetsTheMockRecipes() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        preferredScaleStore.remember(.servings(2.0))
        let presenter = launch()

        presenter.kitchenFeatureDidTapSettings()
        presenter.settingsFeatureDidSelectRecipeRepositoryKind(.mock)
        presenter.settingsFeatureDidConfirmReset()

        #expect(presenter.viewModel?.screen.identity == .onboarding)
        #expect(presenter.viewModel?.openSettings == nil)
        #expect(kitchenRestorationStore.restoration() == nil)
        #expect(launch().viewModel?.screen.identity == .onboarding)
        #expect(preferredScaleStore.preferredScale == .asWritten)
    }

    @Test("the scale picked is kept across instances, and as written once cleared")
    func preferredScaleRoundTrip() {
        #expect(preferredScaleStore.preferredScale == .asWritten)

        preferredScaleStore.remember(.multiplier(1.5))

        #expect(preferredScaleStore.preferredScale == .multiplier(1.5))

        preferredScaleStore.clear()

        #expect(preferredScaleStore.preferredScale == .asWritten)
    }

    @Test("onboarding forgets what the last kitchen had open, which belongs to recipes the next may not read")
    func onboardingForgetsTheKitchen() {
        kitchenRestorationStore.save(crepesRestoration)

        #expect(launch().viewModel?.screen.identity == .onboarding)
        #expect(kitchenRestorationStore.restoration() == nil)
    }

    @Test("the kitchen keeps what it had open across a launch")
    func kitchenKeepsWhatItHadOpen() {
        launch().onboardingFeatureDidChooseMockRecipes()
        kitchenRestorationStore.save(crepesRestoration)

        #expect(kitchen(of: launch())?.kind == .mock)
        #expect(kitchenRestorationStore.restoration() == crepesRestoration)
    }
}
