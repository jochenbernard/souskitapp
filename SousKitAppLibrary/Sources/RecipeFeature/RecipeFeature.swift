import SwiftUI

/// One recipe, rendered at the scale a cook chose.
public struct RecipeFeature {
    /// What the cooking screen zooms out of: the button that starts cooking.
    public static let cookingTransitionID = "startCooking"

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
    /// - Parameter cookingTransition: Where the cooking screen zooms out of the button that starts cooking, by
    ///   ``cookingTransitionID``.
    /// - Returns: The view to push on a navigation stack.
    @MainActor
    public func makeView(cookingTransition: Namespace.ID) -> some View {
        RecipeFeatureView(
            presenter: presenter,
            viewModel: viewModel,
            cookingTransition: cookingTransition
        )
    }
}
