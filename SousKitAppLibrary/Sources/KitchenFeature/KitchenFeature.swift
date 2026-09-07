import SwiftUI

/// Everything the app does once a recipe directory is set: the recipes in it, one recipe, and
/// cooking from one.
public struct KitchenFeature {
    private let viewModel: KitchenFeatureViewModel

    init(viewModel: KitchenFeatureViewModel) {
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to place in a scene.
    @MainActor
    public func makeView() -> some View {
        KitchenFeatureView(viewModel: viewModel)
    }
}
