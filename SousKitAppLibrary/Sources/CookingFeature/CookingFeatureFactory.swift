import SousKit

/// Builds ``CookingFeature`` with what it drives.
public struct CookingFeatureFactory: Sendable {
    private let idleTimer: IdleTimer

    /// Creates a factory.
    ///
    /// - Parameter idleTimer: What keeps the screen on while the cooking screen is up.
    public init(idleTimer: IdleTimer) {
        self.idleTimer = idleTimer
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipe: The recipe to cook from, already read.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    public func makeCookingFeature(
        recipe: Recipe,
        handler: CookingFeatureHandler
    ) -> CookingFeature {
        let viewModel = CookingFeatureViewModel(recipe: recipe)
        let presenter = CookingFeaturePresenter(
            handler: handler,
            idleTimer: idleTimer,
            viewModel: viewModel
        )
        return CookingFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
