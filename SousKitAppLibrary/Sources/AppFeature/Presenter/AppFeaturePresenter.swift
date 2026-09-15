import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// Moves the app between onboarding and the kitchen.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeRepositoryStore: RecipeRepositoryStore

    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        recipeRepositoryStore: RecipeRepositoryStore
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.recipeRepositoryStore = recipeRepositoryStore
    }

    /// The screen a repository calls for: the kitchen reading it, or onboarding where there is none.
    ///
    /// - Parameter recipeRepository: The repository recipes are read from, or `nil` before one is connected.
    /// - Returns: The screen, reporting to this presenter.
    func makeScreen(recipeRepository: RecipeRepository?) -> AppScreen {
        guard let recipeRepository else {
            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeRepository: recipeRepository,
                handler: self
            )
        )
    }

    func onboardingFeatureDidFinish(recipeRepository: RecipeRepository) {
        viewModel?.screen = makeScreen(recipeRepository: recipeRepository)
    }

    func kitchenFeatureDidConfirmReset() {
        recipeRepositoryStore.clear()
        viewModel?.screen = makeScreen(recipeRepository: nil)
    }
}
