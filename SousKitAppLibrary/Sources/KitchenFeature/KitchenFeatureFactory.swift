import CookingFeature
import RecipeFeature
import RecipeLibrary
import SousKit

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    private let parser: SousParser
    private let preferredScaleStore: PreferredScaleStore
    private let timerScheduler: TimerScheduler

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - parser: What the kitchen reads Sous with.
    ///   - preferredScaleStore: Where the scale recipes open on is remembered.
    ///   - timerScheduler: What cooking runs its timers on.
    public init(
        parser: SousParser,
        preferredScaleStore: PreferredScaleStore,
        timerScheduler: TimerScheduler
    ) {
        self.parser = parser
        self.preferredScaleStore = preferredScaleStore
        self.timerScheduler = timerScheduler
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeRepository: The repository recipes are read from.
    ///   - restoration: What the kitchen opens again once its recipe is listed, or `nil` to open on its recipe list.
    ///   - handler: What the feature reports out of the kitchen to.
    /// - Returns: The feature.
    @MainActor
    public func makeKitchenFeature(
        recipeRepository: RecipeRepository,
        restoration: KitchenFeatureRestoration?,
        handler: KitchenFeatureHandler
    ) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: recipeRepository.name)
        viewModel.isRestoring = restoration != nil
        let presenter = KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: ApplicationIdleTimer(),
                timerScheduler: timerScheduler
            ),
            handler: handler,
            parser: parser,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                preferredScaleStore: preferredScaleStore,
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            restoration: restoration,
            viewModel: viewModel
        )

        return KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
