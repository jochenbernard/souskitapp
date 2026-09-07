import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// A class, and the view model it writes arrives after it: the onboarding feature this handles
/// is built before the view model that holds it, so a copied struct would write to a stale one.
final class AppFeaturePresenter: AppFeaturePresenterProtocol, OnboardingFeatureHandler {
    var viewModel: AppFeatureViewModel?

    private let kitchenFeatureFactory: KitchenFeatureFactory

    init(kitchenFeatureFactory: KitchenFeatureFactory) {
        self.kitchenFeatureFactory = kitchenFeatureFactory
    }

    func onboardingFeatureDidFinish(recipeDirectory: RecipeDirectory) {
        viewModel?.screen = .kitchen(kitchenFeatureFactory.makeKitchenFeature(recipeDirectory: recipeDirectory))
    }
}
