import SwiftUI

/// Cooking from one recipe: its steps, and nothing else.
public struct CookingFeature {
    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to push on a navigation stack.
    @MainActor
    public func makeView() -> some View {
        CookingFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
