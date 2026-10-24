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

    /// Starts cooking the recipe as the screen's button does, once the recipe is read, which reports it to the handler.
    ///
    /// A recipe that cannot be read, or has no steps, starts nothing.
    @MainActor
    public func startCooking() {
        presenter.didRequestCooking()
    }

    /// Opens the screen's scale sheet, once the recipe is read.
    @MainActor
    public func showScale() {
        presenter.didRequestScaling()
    }

    /// A glance at the recipe before it is opened, which reads the recipe as it appears.
    ///
    /// Its height follows what it holds, so it is offered no fixed height.
    ///
    /// - Parameter placeholder: What the recipe's card shows where it has no picture, which the glance shows in its
    ///   place too.
    /// - Returns: The view to show as the recipe's preview.
    @MainActor
    public func makePreview(placeholder: RecipePlaceholder) -> some View {
        RecipePreviewView(
            presenter: presenter,
            viewModel: viewModel,
            placeholder: placeholder
        )
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
