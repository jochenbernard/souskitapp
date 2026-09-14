import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// A class, and the view model it writes arrives after it: the onboarding feature this handles
/// is built before the view model that holds it, so a copied struct would write to a stale one.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler, KitchenFeatureHandler {
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

    func onboardingFeatureDidFinish(recipeDirectory: RecipeDirectory) {
        viewModel?.screen = .kitchen(
            kitchenFeatureFactory.makeKitchenFeature(
                recipeDirectory: recipeDirectory,
                handler: self
            )
        )
    }

    func kitchenFeatureDidConfirmReset() {
        recipeDirectoryStore.clear()
        viewModel?.screen = .onboarding(onboardingFeatureFactory.makeOnboardingFeature(handler: self))
    }
}
