import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// Moves the app between onboarding and the kitchen.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler {
    // Set after init, and a class so every copy sees it: the features this handles are built first.
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory
    private let onboardingFeatureFactory: OnboardingFeatureFactory
    private let recipeDirectoryStore: RecipeDirectoryStore

    init(
        kitchenFeatureFactory: KitchenFeatureFactory,
        onboardingFeatureFactory: OnboardingFeatureFactory,
        recipeDirectoryStore: RecipeDirectoryStore
    ) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
        self.onboardingFeatureFactory = onboardingFeatureFactory
        self.recipeDirectoryStore = recipeDirectoryStore
    }

    /// The screen a directory calls for: the kitchen reading it, or onboarding where there is none.
    ///
    /// - Parameter recipeDirectory: The directory recipes are read from, or `nil` before one is picked.
    /// - Returns: The screen, reporting to this presenter.
    func makeScreen(recipeDirectory: RecipeDirectory?) -> AppScreen {
        guard let recipeDirectory else {
            return .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
        }

        return .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeDirectory: recipeDirectory,
                handler: self
            )
        )
    }

    func onboardingFeatureDidFinish(recipeDirectory: RecipeDirectory) {
        viewModel?.screen = makeScreen(recipeDirectory: recipeDirectory)
    }

    func kitchenFeatureDidConfirmReset() {
        recipeDirectoryStore.clear()
        viewModel?.screen = makeScreen(recipeDirectory: nil)
    }
}
