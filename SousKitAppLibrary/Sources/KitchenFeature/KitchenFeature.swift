import SwiftUI

/// Everything the app does once a recipe repository is connected: the recipes in it, one recipe, and
/// cooking from one.
public struct KitchenFeature {
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// What the kitchen has pushed on the stack its view is the root of.
    @MainActor
    public var path: Binding<NavigationPath> {
        Binding(
            get: { NavigationPath(viewModel.pushedScreens) },
            // The kitchen pushes from its own rows, so the stack only ever changes the path by popping it.
            set: { path in presenter.didPop(toCount: path.count) }
        )
    }

    /// Whether the kitchen has yet to open what a cold start found open, which its stack pushes without animating.
    @MainActor
    public var isRestoring: Bool {
        viewModel.isRestoring
    }

    /// The feature's screen, which pushes its recipes on the stack it is placed in.
    ///
    /// - Returns: The view to place at the root of a navigation stack driven by ``path``.
    @MainActor
    public func makeView() -> some View {
        KitchenFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
