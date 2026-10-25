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

    /// - Parameter folderPath: The repository's name, then the folders leading down to the recipe.
    init(
        recipeEntry: RecipeEntry,
        folderPath: [String]
    ) {
        self.recipeEntry = recipeEntry
        self.folderPath = folderPath
        self.picture = recipeEntry.picture
        // A recipe naming no picture shows its placeholder from the first frame of the push.
        self.headerPicture = recipeEntry.picture == nil ? .placeholder : .reading
    }
}
