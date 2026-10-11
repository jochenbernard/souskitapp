import CookingFeature
import RecipeFeature
import RecipeLibrary
import SousKit

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    private let parser: SousParser
    private let preferredScaleStore: PreferredScaleStore
    private let restorationStore: KitchenRestorationStore

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - parser: What the kitchen reads Sous with.
    ///   - preferredScaleStore: Where the scale recipes open on is remembered.
    ///   - restorationStore: Where the kitchen keeps what it has open for the next cold start.
    public init(
        parser: SousParser,
        preferredScaleStore: PreferredScaleStore,
        restorationStore: KitchenRestorationStore
    ) {
        self.parser = parser
        self.preferredScaleStore = preferredScaleStore
        self.restorationStore = restorationStore
    }

    /// Builds the feature, which opens what the kitchen had open when the app last ran once its recipe is listed.
    ///
    /// - Parameters:
    ///   - recipeRepository: The repository recipes are read from.
    ///   - handler: What the feature reports out of the kitchen to.
    /// - Returns: The feature.
    @MainActor
    public func makeKitchenFeature(
        recipeRepository: RecipeRepository,
        handler: KitchenFeatureHandler
    ) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: recipeRepository.name)
        viewModel.isRestoring = restorationStore.restoration() != nil
        let timerScheduler = AlarmTimerScheduler()
        let presenter = KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: ApplicationIdleTimer(),
                timerScheduler: timerScheduler
            ),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                preferredScaleStore: preferredScaleStore,
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            restorationSettleTime: .seconds(5),
            restorationStore: restorationStore,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )

        return KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
