import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// A repository reading one picture for every recipe, or failing every read where it holds none, and counting the
/// boxes it reads the picture for.
@MainActor
final class PictureRepositorySpy: RecipeRepository {
    nonisolated let name = "Recipes"

    private(set) var thumbnailBoxes: [CGSize] = []

    /// The picture read for every recipe, or `nil` for a read that fails.
    var thumbnail: CGImage?

    nonisolated private let parser = SousParser()

    init(thumbnail: CGImage?) {
        self.thumbnail = thumbnail
    }

    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        AsyncStream(unfolding: { nil })
    }

    func refresh() {}

    func readRecipe(of _: RecipeEntry) -> Parsed<Recipe> {
        parser.parseRecipe("")
    }

    func readThumbnail(of _: RecipePicture, filling pixelSize: CGSize) throws -> CGImage {
        thumbnailBoxes.append(pixelSize)

        guard let thumbnail else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return thumbnail
    }
}
