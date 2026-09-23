import SwiftUI

/// One recipe, rendered at the scale a cook chose.
public struct RecipeFeature {
    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel

    init(
        presenter: RecipeFeaturePresenterProtocol,
        viewModel: RecipeFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to push on a navigation stack.
    @MainActor
    public func makeView() -> some View {
        RecipeFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
