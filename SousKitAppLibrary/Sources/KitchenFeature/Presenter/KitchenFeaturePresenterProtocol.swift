import CoreGraphics
import RecipeLibrary

/// What ``KitchenFeature`` and ``KitchenFeatureView`` report to.
protocol KitchenFeaturePresenterProtocol {
    /// The stack the kitchen's screens are pushed on is on screen, and the call is cancelled when it leaves.
    @MainActor
    func stackDidAppear() async

    /// The app came back to the foreground.
    @MainActor
    func didBecomeActive() async

    /// A row on a screen of the kitchen was pressed.
    ///
    /// - Parameters:
    ///   - screen: The screen the row pushes.
    ///   - origin: The screen the row is on, or `nil` for the kitchen's own.
    @MainActor
    func didPush(_ screen: KitchenScreen, from origin: KitchenScreen?)

    /// The stack popped screens.
    ///
    /// - Parameter count: How many screens are left on it.
    @MainActor
    func didPop(toCount count: Int)

    /// The text searched for on a folder's screen changed.
    ///
    /// - Parameters:
    ///   - text: The text, which may be empty.
    ///   - folderPath: The names of the folders leading down to the folder searched, or none for the top.
    @MainActor
    func didChangeSearchText(_ text: String, in folderPath: [String])

    @MainActor
    func didDismissCooking()

    /// A card showing a recipe's picture is on screen, and the call is cancelled when it leaves or its size changes.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - pixelSize: The box the card shows the picture in, in pixels.
    /// - Returns: The picture scaled to fill the box, or `nil` where it cannot be read.
    @MainActor
    func thumbnail(of picture: RecipePicture, filling pixelSize: CGSize) async -> CGImage?

    /// The picture a card shows at once, before reading it at its size: the one read last for the picture as it is now.
    ///
    /// - Parameter picture: The picture.
    /// - Returns: The picture, at whatever size it was read, or `nil` where it has not been read as it is now.
    @MainActor
    func lastThumbnail(of picture: RecipePicture) -> CGImage?
}
