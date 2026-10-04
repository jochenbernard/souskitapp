import SousKit

/// Builds ``CookingFeature`` with what it drives.
public struct CookingFeatureFactory: Sendable {
    private let idleTimer: IdleTimer
    private let timerScheduler: TimerScheduler

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - idleTimer: What keeps the screen on while the cooking screen is up.
    ///   - timerScheduler: What counts down the timers a cook starts from the steps.
    public init(
        idleTimer: IdleTimer,
        timerScheduler: TimerScheduler
    ) {
        self.idleTimer = idleTimer
        self.timerScheduler = timerScheduler
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipe: The recipe to cook from, already read.
    ///   - title: The recipe's title, as the cooking screen shows it.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    public func makeCookingFeature(
        recipe: Recipe,
        title: String,
        handler: CookingFeatureHandler
    ) -> CookingFeature {
        let viewModel = CookingFeatureViewModel(
            recipe: recipe,
            title: title
        )
        let presenter = CookingFeaturePresenter(
            handler: handler,
            idleTimer: idleTimer,
            timerScheduler: timerScheduler,
            viewModel: viewModel
        )
        return CookingFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
