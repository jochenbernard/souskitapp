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

    /// The feature's screen, which pushes its recipes on the stack it is placed in.
    ///
    /// - Returns: The view to place at the root of a navigation stack.
    @MainActor
    public func makeView() -> some View {
        KitchenFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
