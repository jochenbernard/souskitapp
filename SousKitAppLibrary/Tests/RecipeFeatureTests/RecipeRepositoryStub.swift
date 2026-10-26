import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// A repository reading and exporting every recipe as one text, or failing every read where it holds none, and every
/// export where it is told to.
struct RecipeRepositoryStub: RecipeRepository {
    let name = "Recipes"

    private let parser = SousParser()
    private let text: String?
    private let failsExport: Bool

    init(text: String?, failsExport: Bool = false) {
        self.text = text
        self.failsExport = failsExport
    }

    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        AsyncStream(unfolding: { nil })
    }

    func refresh() {}

    func readRecipe(of _: RecipeEntry) throws -> Parsed<Recipe> {
        guard let text else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return parser.parseRecipe(text)
    }

    func readThumbnail(of _: RecipePicture, filling _: CGSize) throws -> CGImage {
        throw CocoaError(.fileReadNoSuchFile)
    }

    /// Writes the text to a file in a folder of its own under the temporary directory, named after the recipe's id.
    func exportRecipeFile(of entry: RecipeEntry) throws -> URL {
        guard let text, !failsExport else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        let folderURL = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let fileURL = folderURL.appending(path: "\(entry.id).sous")
        try Data(text.utf8).write(to: fileURL)

        return fileURL
    }
}
