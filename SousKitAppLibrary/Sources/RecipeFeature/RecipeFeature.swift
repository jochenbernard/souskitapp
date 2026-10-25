import RecipeLibrary
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

    /// Shows the recipe as it is listed now, such as with the picture a download brought.
    ///
    /// - Parameter recipeEntry: The recipe, listed again.
    @MainActor
    public func show(_ recipeEntry: RecipeEntry) {
        presenter.entryDidChange(recipeEntry)
    }

    /// The feature's screen.
    ///
    /// - Parameters:
    ///   - placeholder: What the recipe's card shows where it has no picture, which the screen shows in its place
    ///     too.
    ///   - cookingTransition: Where the cooking screen zooms out of the button that starts cooking, by
    ///     ``cookingTransitionID``.
    /// - Returns: The view to push on a navigation stack.
    @MainActor
    public func makeView(placeholder: RecipePlaceholder, cookingTransition: Namespace.ID) -> some View {
        RecipeFeatureView(
            presenter: presenter,
            viewModel: viewModel,
            placeholder: placeholder,
            cookingTransition: cookingTransition
        )
    }
}
