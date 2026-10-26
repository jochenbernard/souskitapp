import CoreGraphics
import Foundation
import Observation
import RecipeLibrary

@Observable
@MainActor
final class RecipeFeatureViewModel {
    let recipeEntry: RecipeEntry
    let folderPath: [String]
    var picture: RecipePicture?
    var headerPicture: HeaderPicture
    var recipeContent: RecipeContent = .reading
    var expandedSections = RecipeSection.openByDefault
    var isScaling = false
    var scaleText = ""
    var sharedFileURL: URL?

    /// - Parameters:
    ///   - folderPath: The repository's name, then the folders leading down to the recipe.
    ///   - thumbnail: The recipe's picture as its card shows it, or `nil` where the card shows none.
    init(
        recipeEntry: RecipeEntry,
        folderPath: [String],
        thumbnail: CGImage? = nil
    ) {
        self.recipeEntry = recipeEntry
        self.folderPath = folderPath
        self.picture = recipeEntry.picture
        // The card's picture stands in from the first frame of the zoom until the header reads its own.
        self.headerPicture = if recipeEntry.picture == nil {
            .placeholder
        } else if let thumbnail {
            .read(thumbnail)
        } else {
            .reading
        }
    }
}
