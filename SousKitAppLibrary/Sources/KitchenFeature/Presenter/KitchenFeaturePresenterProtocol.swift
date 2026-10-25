import CoreGraphics
import RecipeLibrary

/// What ``KitchenFeature`` and ``KitchenFeatureView`` report to.
protocol KitchenFeaturePresenterProtocol {
    /// The stack the kitchen's screens are pushed on is on screen, and the call is cancelled when it leaves.
    @MainActor
    func stackDidAppear() async

    /// The kitchen's own screen is on screen, with nothing pushed over it, and the call is cancelled when it leaves.
    @MainActor
    func topScreenDidAppear() async

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

    /// A recipe file was handed to the app to open.
    ///
    /// - Parameter document: The file.
    @MainActor
    func didOpen(_ document: RecipeDocument)

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

    /// A screen of the kitchen has appeared on the stack, its push finished.
    ///
    /// - Parameter screen: The screen, or `nil` for the kitchen's own.
    @MainActor
    func screenDidAppear(_ screen: KitchenScreen?)

    @MainActor
    func didDismissCooking()

    /// A recipe's card was long pressed, for a preview of the recipe.
    @MainActor
    func didPreview(_ recipeEntry: RecipeEntry)

    /// A recipe card's menu chose to cook the recipe, which pushes it and then starts cooking from it.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe.
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    @MainActor
    func didChooseCooking(_ recipeEntry: RecipeEntry, from origin: KitchenScreen?)

    /// A recipe card's menu chose to scale the recipe, which pushes it with its scale sheet open.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe.
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    @MainActor
    func didChooseScaling(_ recipeEntry: RecipeEntry, from origin: KitchenScreen?)

    /// The menu of a recipe a search found chose to show the folder the recipe sits in, which pushes the folder.
    ///
    /// - Parameters:
    ///   - recipeEntry: The recipe.
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    @MainActor
    func didChooseFolder(of recipeEntry: RecipeEntry, from origin: KitchenScreen?)

    /// A folder card's menu chose to search in the folder, which pushes it with its search field active.
    ///
    /// - Parameters:
    ///   - folderPath: The names of the folders leading down to the folder, its own last.
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    @MainActor
    func didChooseSearch(inFolderAt folderPath: [String], from origin: KitchenScreen?)

    /// A folder's search field became active or stopped being active.
    ///
    /// - Parameters:
    ///   - isPresented: Whether it is active.
    ///   - folderPath: The names of the folders leading down to the folder, or none for the top.
    @MainActor
    func didChangeIsSearchPresented(_ isPresented: Bool, in folderPath: [String])

    /// A card showing a recipe's picture is on screen, and the call is cancelled when it leaves or its size changes.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - pixelSize: The box the card shows the picture in, in pixels.
    @MainActor
    func pictureDidAppear(_ picture: RecipePicture, filling pixelSize: CGSize) async
}
