import SwiftUI

/// What the user sets for the whole app: the folder recipes are read from, the scale recipes open on, and what build
/// of the app this is.
public struct SettingsFeature {
    private let presenter: SettingsFeaturePresenterProtocol
    private let viewModel: SettingsFeatureViewModel

    init(
        presenter: SettingsFeaturePresenterProtocol,
        viewModel: SettingsFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    /// The feature's screen.
    ///
    /// - Returns: The view to present in a sheet.
    @MainActor
    public func makeView() -> some View {
        SettingsFeatureView(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
