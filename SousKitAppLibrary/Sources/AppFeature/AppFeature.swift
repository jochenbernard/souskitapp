import SwiftUI

/// The app's one screen at a time: onboarding until a recipe repository is connected, the kitchen
/// after that.
struct AppFeature {
    private let presenter: AppFeaturePresenterProtocol
    private let viewModel: AppFeatureViewModel

    init(
        presenter: AppFeaturePresenterProtocol,
        viewModel: AppFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to place in a scene.
    @MainActor
    func makeView() -> some View {
        AppFeatureView(viewModel: viewModel)
    }
}
