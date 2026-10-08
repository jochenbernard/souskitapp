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
                restorationStore: kitchenRestorationStore,
                settingsFeatureFactory: SettingsFeatureFactory(
                    appVersion: AppVersion(bundle: .main),
                    preferredScaleStore: preferredScaleStore,
                    recipeRepositoryStore: recipeRepositoryStore
                )
            ),
            kitchenRestorationStore: kitchenRestorationStore,
            mockRecipeRepository: MockRecipeRepository(parser: parser),
            onboardingFeatureFactory: OnboardingFeatureFactory(recipeRepositoryStore: recipeRepositoryStore),
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryKindStore: recipeRepositoryKindStore,
            recipeRepositoryStore: recipeRepositoryStore
        )
        presenter.viewModel = AppFeatureViewModel(screen: presenter.makeScreen())

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

    @Test("picking the folder in the kitchen on the mock recipes goes back to onboarding before a folder is picked")
    func folderWithoutAFolderOpensOnboarding() {
        let presenter = launch()

        presenter.onboardingFeatureDidChooseMockRecipes()
        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(presenter.viewModel?.screen.identity == .onboarding)
    }

    @Test("the kitchen moves between the folder picked and the mock recipes")
    func kitchenMovesBetweenKinds() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        let presenter = launch()

        #expect(kitchen(of: presenter)?.kind == .files)

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(kitchen(of: presenter)?.kind == .mock)

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(kitchen(of: presenter)?.kind == .files)
    }

    @Test("a folder connected in the kitchen opens a kitchen of its own on it, over the mock recipes too")
    func folderConnectedInTheKitchen() throws {
        let presenter = launch()

        presenter.onboardingFeatureDidChooseMockRecipes()
        let mockKitchen = try #require(kitchen(of: presenter))

        presenter.kitchenFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )
        let folderKitchen = try #require(kitchen(of: presenter))

        #expect(folderKitchen.kind == .files)
        #expect(folderKitchen.id != mockKitchen.id)

        presenter.kitchenFeatureDidConnectRecipeRepository(
            try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        )

        #expect(kitchen(of: presenter)?.id != folderKitchen.id)
        #expect(kitchen(of: launch())?.kind == .files)
    }

    @Test("a reset forgets the mock recipes and the scale along with the folder")
    func resetForgetsTheMockRecipes() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        preferredScaleStore.remember(.servings(2.0))
        let presenter = launch()

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.mock)
        presenter.kitchenFeatureDidConfirmReset()

        #expect(presenter.viewModel?.screen.identity == .onboarding)
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
