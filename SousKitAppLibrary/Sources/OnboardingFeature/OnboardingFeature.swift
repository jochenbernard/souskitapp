import SwiftUI

/// The first run: picking the directory the user's recipes are read from.
public struct OnboardingFeature {
    private let presenter: OnboardingFeaturePresenterProtocol
    private let viewModel: OnboardingFeatureViewModel

    init(
        presenter: OnboardingFeaturePresenterProtocol,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to place in a scene.
    @MainActor
    public func makeView() -> some View {
        OnboardingFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
