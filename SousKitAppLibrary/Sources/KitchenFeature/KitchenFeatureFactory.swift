import CookingFeature
import RecipeFeature
import RecipeLibrary
import SousKit

/// Builds ``KitchenFeature`` with what it reads.
public struct KitchenFeatureFactory: Sendable {
    private let parser: SousParser
    private let restorationStore: KitchenRestorationStore

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - parser: What the kitchen reads Sous with.
    ///   - restorationStore: Where the kitchen keeps what it has open for the next cold start.
    public init(
        parser: SousParser,
        restorationStore: KitchenRestorationStore
    ) {
        self.parser = parser
        self.restorationStore = restorationStore
    }

    /// Builds the feature, opening what the kitchen had open when the app last ran.
    ///
    /// - Parameters:
    ///   - recipeRepository: The repository recipes are read from.
    ///   - recipeRepositoryKind: The kind of repository `recipeRepository` is.
    ///   - handler: What the feature reports out of the kitchen to.
    /// - Returns: The feature.
    @MainActor
    public func makeKitchenFeature(
        recipeRepository: RecipeRepository,
        recipeRepositoryKind: RecipeRepositoryKind,
        handler: KitchenFeatureHandler
    ) -> KitchenFeature {
        let viewModel = KitchenFeatureViewModel(
            recipeRepositoryName: recipeRepository.name,
            recipeRepositoryKind: recipeRepositoryKind
        )
        let presenter = KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(
                idleTimer: ApplicationIdleTimer(),
                timerScheduler: AlarmTimerScheduler()
            ),
            handler: handler,
            recipeFeatureFactory: RecipeFeatureFactory(
                parser: parser,
                recipeRepository: recipeRepository
            ),
            recipeRepository: recipeRepository,
            restorationStore: restorationStore,
            viewModel: viewModel
        )
        presenter.restore()

        return KitchenFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
