@testable import AppFeature
import FileRecipeLibrary
import Foundation
import KitchenFeature
import MockRecipeLibrary
import OnboardingFeature
import RecipeLibrary
import SousKit
import Testing

@MainActor
@Suite("App feature presenter")
final class AppFeaturePresenterTests {
    private let parser = SousParser()
    private let suiteName: String
    private let userDefaults: UserDefaults

    init() throws {
        self.suiteName = "AppFeaturePresenterTests.\(UUID().uuidString)"
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
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
        let kitchenRestorationStore = KitchenRestorationStore(userDefaults: userDefaults)
        let presenter = AppFeaturePresenter(
            kitchenFeatureFactory: KitchenFeatureFactory(
                parser: parser,
                restorationStore: kitchenRestorationStore
            ),
            kitchenRestorationStore: kitchenRestorationStore,
            mockRecipeRepository: MockRecipeRepository(parser: parser),
            onboardingFeatureFactory: OnboardingFeatureFactory(recipeRepositoryStore: recipeRepositoryStore),
            recipeRepositoryKindStore: RecipeRepositoryKindStore(userDefaults: userDefaults),
            recipeRepositoryStore: recipeRepositoryStore
        )
        presenter.viewModel = AppFeatureViewModel(screen: presenter.makeScreen())

        return presenter
    }

    @Test("onboarding opens before a folder is picked")
    func onboardingBeforeAFolder() {
        #expect(launch().viewModel?.screen.identity == .onboarding)
    }

    @Test("choosing the mock recipes on onboarding opens the kitchen on them")
    func mockRecipesFromOnboarding() {
        let presenter = launch()

        presenter.onboardingFeatureDidChooseMockRecipes()

        #expect(presenter.viewModel?.screen.identity == .kitchen(.mock))
    }

    @Test("the next launch opens on the mock recipes once they are chosen")
    func mockRecipesAreRemembered() {
        launch().onboardingFeatureDidChooseMockRecipes()

        #expect(launch().viewModel?.screen.identity == .kitchen(.mock))
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

        #expect(presenter.viewModel?.screen.identity == .kitchen(.files))

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.mock)

        #expect(presenter.viewModel?.screen.identity == .kitchen(.mock))

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.files)

        #expect(presenter.viewModel?.screen.identity == .kitchen(.files))
    }

    @Test("a reset forgets the mock recipes along with the folder")
    func resetForgetsTheMockRecipes() throws {
        _ = try makeRecipeRepositoryStore().connectRecipeDirectory(at: URL.temporaryDirectory)
        let presenter = launch()

        presenter.kitchenFeatureDidSelectRecipeRepositoryKind(.mock)
        presenter.kitchenFeatureDidConfirmReset()

        #expect(presenter.viewModel?.screen.identity == .onboarding)
        #expect(launch().viewModel?.screen.identity == .onboarding)
    }

    @Test("onboarding forgets what the last kitchen had open, which belongs to recipes the next may not read")
    func onboardingForgetsTheKitchen() {
        userDefaults.set(Data(), forKey: "KitchenRestorationStore.restoration")

        #expect(launch().viewModel?.screen.identity == .onboarding)
        #expect(userDefaults.object(forKey: "KitchenRestorationStore.restoration") == nil)
    }

    @Test("the kitchen keeps what it had open across a launch")
    func kitchenKeepsWhatItHadOpen() {
        launch().onboardingFeatureDidChooseMockRecipes()
        userDefaults.set(Data(), forKey: "KitchenRestorationStore.restoration")

        #expect(launch().viewModel?.screen.identity == .kitchen(.mock))
        #expect(userDefaults.object(forKey: "KitchenRestorationStore.restoration") != nil)
    }
}
