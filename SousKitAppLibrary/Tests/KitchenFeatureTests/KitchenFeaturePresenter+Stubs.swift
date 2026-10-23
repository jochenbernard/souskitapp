import CookingFeature
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SousKit

extension KitchenFeaturePresenter {
    /// A presenter on stubs, reading the folder, built to open the given restoration again, and greeting by the clock.
    @MainActor
    static func stubbed(
        viewModel: KitchenFeatureViewModel,
        parser: SousParser,
        greetingClock: KitchenGreetingClock = .system,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepository = RecipeRepositorySpy(),
        restoration: KitchenFeatureRestoration? = nil
    ) -> Self {
        Self(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: TimerSchedulerStub()
            ),
            greetingClock: greetingClock,
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                preferredScaleStore: PreferredScaleStoreStub(),
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            restoration: restoration,
            viewModel: viewModel
        )
    }
}
