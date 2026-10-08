import Foundation
import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// Moves the app between onboarding and the kitchen, and the kitchen between the kinds of recipe repository.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let kitchenRestorationStore: KitchenRestorationStore
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let preferredScaleStore: UserDefaultsPreferredScaleStore
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore

    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        kitchenRestorationStore: KitchenRestorationStore,
        mockRecipeRepository: RecipeRepository,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        preferredScaleStore: UserDefaultsPreferredScaleStore,
        recipeRepositoryKindStore: RecipeRepositoryKindStore,
        recipeRepositoryStore: RecipeRepositoryStore
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.kitchenRestorationStore = kitchenRestorationStore
        self.mockRecipeRepository = mockRecipeRepository
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepositoryKindStore = recipeRepositoryKindStore
        self.recipeRepositoryStore = recipeRepositoryStore
    }

    /// The screen the remembered kind of repository calls for: the kitchen reading it, or onboarding where the folder
    /// is to be picked.
    ///
    /// - Returns: The screen, reporting to this presenter.
    @MainActor
    func makeScreen() -> AppScreen {
        switch recipeRepositoryKindStore.recipeRepositoryKind {
        case .files:
            makeScreen(recipeRepository: recipeRepositoryStore.makeRecipeRepository(), kind: .files)

        case .mock:
            makeScreen(recipeRepository: mockRecipeRepository, kind: .mock)
        }
    }

    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository) {
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository, kind: .files)
    }

    func onboardingFeatureDidChooseMockRecipes() {
        selectRecipeRepositoryKind(.mock)
    }

    func kitchenFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository) {
        // A folder picked over the mock recipes is read from now on.
        recipeRepositoryKindStore.remember(.files)
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository, kind: .files)
    }

    func kitchenFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        selectRecipeRepositoryKind(recipeRepositoryKind)
    }

    func kitchenFeatureDidConfirmReset() {
        preferredScaleStore.clear()
        recipeRepositoryKindStore.clear()
        recipeRepositoryStore.clear()
        viewModel?.screen = makeScreen()
    }

    @MainActor
    private func makeScreen(
        recipeRepository: RecipeRepository?,
        kind: RecipeRepositoryKind
    ) -> AppScreen {
        guard let recipeRepository else {
            // What the last kitchen had open belongs to recipes the next one may not read.
            kitchenRestorationStore.clear()

            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeRepository: recipeRepository,
                recipeRepositoryKind: kind,
                handler: self
            ),
            id: UUID()
        )
    }

    @MainActor
    private func selectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        guard recipeRepositoryKind != recipeRepositoryKindStore.recipeRepositoryKind else {
            return
        }

        recipeRepositoryKindStore.remember(recipeRepositoryKind)
        viewModel?.screen = makeScreen()
    }
}
