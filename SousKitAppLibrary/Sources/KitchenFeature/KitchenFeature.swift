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
    /// - Parameter toolbarItem: What the trailing end of the navigation bar holds on the recipe list and on every
    ///   folder, though not on a recipe.
    /// - Returns: The view to place at the root of a navigation stack driven by ``path``.
    @MainActor
    public func makeView(@ViewBuilder toolbarItem: () -> some View) -> some View {
        KitchenFeatureView(
            presenter: presenter,
            viewModel: viewModel,
            toolbarItem: toolbarItem()
        )
    }

    /// Keeps every screen of the kitchen showing the repository's recipes as they change, until the task running it
    /// is cancelled.
    ///
    /// Run it in a task on the navigation stack driven by ``path`` rather than on the view from
    /// ``makeView(toolbarItem:)``, which a pushed screen takes off screen, cancelling the tasks on it.
    @MainActor
    public func followRecipes() async {
        await presenter.stackDidAppear()
    }
}
