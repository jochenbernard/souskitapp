import CoreGraphics
import Foundation
import SousKit

/// The user's recipes, listed and read wherever they are kept.
public protocol RecipeRepository: Sendable {
    /// What the user knows the recipes by, such as the name of the folder holding them.
    var name: String { get }

    /// The recipes, those in folders at any depth included, yielded once now and again after every change to them.
    ///
    /// Cancelling the task iterating the stream ends it, and so does releasing the repository. One stream runs at a
    /// time; a second call ends the first.
    ///
    /// - Returns: The stream.
    func listedRecipes() async -> AsyncStream<Result<[ListedRecipe], Error>>

    /// Reads the recipes again, for the changes that reach the app no other way: a sync that landed while the app
    /// was in the background.
    ///
    /// The recipes read arrive on the stream from ``listedRecipes()``, not by the time the call returns.
    func refresh() async

    /// Reads a recipe and parses it.
    ///
    /// Parsing always lands, so a recipe comes back whatever it holds, with what the parser found wrong beside it.
    /// Only reading the recipe throws.
    ///
    /// - Parameter entry: The recipe to read.
    /// - Returns: The recipe, and the diagnostics from parsing it.
    /// - Throws: Whatever reading the recipe throws.
    func readRecipe(of entry: RecipeEntry) async throws -> Parsed<Recipe>

    /// Reads a recipe's picture, scaled down to fill a box.
    ///
    /// The picture keeps its proportions, so it reaches past the box on one side, and it is never scaled up. A
    /// picture not on the device is fetched first.
    ///
    /// - Parameters:
    ///   - picture: The picture, as an entry lists it.
    ///   - pixelSize: The box, in pixels.
    /// - Returns: The picture, decoded.
    /// - Throws: Whatever fetching or reading the picture throws, or what its contents not being a picture does.
    func readThumbnail(of picture: RecipePicture, filling pixelSize: CGSize) async throws -> CGImage

    /// The id of the recipe a file holds, where the file is one of the repository's recipes.
    ///
    /// - Parameter url: Where the file sits.
    /// - Returns: The id, or `nil` where the repository does not hold the file.
    func recipeID(forFileAt url: URL) -> String?
}
