import CookingFeature
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SousKit

extension KitchenFeaturePresenter {
    /// A presenter on stubs, keeping what the kitchen has open in the given store.
    @MainActor
    static func stubbed(
        viewModel: KitchenFeatureViewModel,
        parser: SousParser,
        restorationStore: KitchenRestorationStore,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepository = RecipeRepositorySpy(),
        timerScheduler: TimerSchedulerStub = TimerSchedulerStub(),
        restorationSettleTime: Duration = .zero
    ) -> Self {
        Self(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: timerScheduler
            ),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(parser: parser, recipeRepository: recipeRepository),
            recipeRepository: recipeRepository,
            restorationSettleTime: restorationSettleTime,
            restorationStore: restorationStore,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }
}
