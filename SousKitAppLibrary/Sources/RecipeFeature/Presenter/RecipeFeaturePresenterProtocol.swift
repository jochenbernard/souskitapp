import CoreGraphics
import RecipeLibrary
import RecipeScaling

/// What ``RecipeFeatureView`` reports to.
protocol RecipeFeaturePresenterProtocol: ScaleSheetPresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    /// The header is on screen at a size its picture is read to fill, and the call is cancelled when it leaves or
    /// changes size.
    ///
    /// - Parameter pixelSize: The header's size at rest, in pixels, which is empty before it is laid out.
    @MainActor
    func headerDidAppear(filling pixelSize: CGSize) async

    /// The recipe is listed again, as it is now.
    @MainActor
    func entryDidChange(_ recipeEntry: RecipeEntry)

    @MainActor
    func didChangeIsExpanded(_ isExpanded: Bool, of section: RecipeSection)

    @MainActor
    func didTapScale()

    @MainActor
    func didTapCook()

    /// The share button was tapped, which opens the share sheet once the recipe's file is copied, unless the recipe is
    /// not read or the call is cancelled first, as it is when the view leaves.
    @MainActor
    func didTapShare() async

    /// The share sheet closed, whether or not it handed the recipe on.
    @MainActor
    func didDismissSharing()

    /// Cooking was asked for from outside the screen, as its button starts it, once the recipe is read.
    @MainActor
    func didRequestCooking()

    /// The scale sheet was asked for from outside the screen, to open once the recipe is read.
    @MainActor
    func didRequestScaling()
}
