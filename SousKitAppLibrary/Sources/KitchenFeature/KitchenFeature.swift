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

    /// The feature's screen.
    ///
    /// - Returns: The view to place in a scene.
    @MainActor
    public func makeView() -> some View {
        KitchenFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
