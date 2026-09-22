import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// Moves the app between onboarding and the kitchen, and the kitchen between the kinds of recipe repository.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let mockRecipeRepository: RecipeRepository
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeRepositoryKindStore: RecipeRepositoryKindStore
    private let recipeRepositoryStore: RecipeRepositoryStore

    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        mockRecipeRepository: RecipeRepository,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        recipeRepositoryKindStore: RecipeRepositoryKindStore,
        recipeRepositoryStore: RecipeRepositoryStore
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.mockRecipeRepository = mockRecipeRepository
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.recipeRepositoryKindStore = recipeRepositoryKindStore
        self.recipeRepositoryStore = recipeRepositoryStore
    }

    /// The screen the remembered kind of repository calls for: the kitchen reading it, or onboarding where the folder
    /// is to be picked.
    ///
    /// - Returns: The screen, reporting to this presenter.
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

    func kitchenFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        selectRecipeRepositoryKind(recipeRepositoryKind)
    }

    func kitchenFeatureDidConfirmReset() {
        recipeRepositoryKindStore.clear()
        recipeRepositoryStore.clear()
        viewModel?.screen = makeScreen()
    }

    private func makeScreen(
        recipeRepository: RecipeRepository?,
        kind: RecipeRepositoryKind
    ) -> AppScreen {
        guard let recipeRepository else {
            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeRepository: recipeRepository,
                recipeRepositoryKind: kind,
                handler: self
            ),
            kind
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
