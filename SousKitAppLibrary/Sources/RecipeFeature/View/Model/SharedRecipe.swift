import CoreTransferable
import RecipeLibrary
import UniformTypeIdentifiers

/// A recipe as the share sheet hands it to another app: its file, copied out of the repository as the sheet opens.
struct SharedRecipe: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .sousRecipe) { sharedRecipe in
            SentTransferredFile(try await sharedRecipe.recipeRepository.exportRecipeFile(of: sharedRecipe.entry))
        }
    }

    let entry: RecipeEntry
    let recipeRepository: RecipeRepository
}
