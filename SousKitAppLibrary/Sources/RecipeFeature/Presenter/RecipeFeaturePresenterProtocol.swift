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
    /// - Parameter pixelSize: The header's size, in pixels, which is empty before it is laid out.
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
}
