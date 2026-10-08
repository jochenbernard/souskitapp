import CookingFeature
import Foundation
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SettingsFeature
import SousKit

extension KitchenFeaturePresenter {
    /// A presenter on stubs, reading the folder, keeping what the kitchen has open in the given store.
    @MainActor
    static func stubbed(
        viewModel: KitchenFeatureViewModel,
        parser: SousParser,
        restorationStore: KitchenRestorationStore,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub(),
        recipeRepository: RecipeRepository = RecipeRepositorySpy(),
        recipeRepositoryKind: RecipeRepositoryKind = .files,
        timerScheduler: TimerSchedulerStub = TimerSchedulerStub(),
        restorationSettleTime: Duration = .zero
    ) -> Self {
        let preferredScaleStore = PreferredScaleStoreStub()

        return Self(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: IdleTimerStub(),
                timerScheduler: timerScheduler
            ),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                preferredScaleStore: preferredScaleStore,
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            recipeRepositoryKind: recipeRepositoryKind,
            restorationSettleTime: restorationSettleTime,
            restorationStore: restorationStore,
            settingsFeatureFactory: SettingsFeatureFactory(
                appVersion: AppVersion(bundle: .main),
                preferredScaleStore: preferredScaleStore,
                recipeRepositoryStore: RecipeRepositoryStoreStub()
            ),
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
    }
}
