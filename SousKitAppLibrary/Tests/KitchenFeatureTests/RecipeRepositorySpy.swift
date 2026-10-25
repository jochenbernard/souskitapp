import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// A repository listing whatever a test sends it, counting its refreshes and reads, and reading the thumbnails a test
/// gives it.
@MainActor
final class RecipeRepositorySpy: RecipeRepository {
    nonisolated let name = "Recipes"

    private(set) var refreshCount = 0
    private(set) var readCount = 0
    private(set) var thumbnailReads: [RecipePicture] = []
    private(set) var exportedEntries: [RecipeEntry] = []

    /// The thumbnail read for each picture, by its id; any other picture fails to read.
    var thumbnails: [String: CGImage] = [:]

    /// What every export throws, or `nil` for exports that succeed.
    var exportError: Error?

    nonisolated private let parser = SousParser()

    private let continuation: AsyncStream<Result<[ListedRecipe], Error>>.Continuation
    private let stream: AsyncStream<Result<[ListedRecipe], Error>>

    init() {
        (self.stream, self.continuation) = AsyncStream.makeStream(of: Result<[ListedRecipe], Error>.self)
    }

    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        stream
    }

    func refresh() {
        refreshCount += 1
    }

    func readRecipe(of _: RecipeEntry) -> Parsed<Recipe> {
        readCount += 1

        return parser.parseRecipe("")
    }

    func readThumbnail(of picture: RecipePicture, filling _: CGSize) throws -> CGImage {
        thumbnailReads.append(picture)

        guard let thumbnail = thumbnails[picture.id] else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return thumbnail
    }

    /// Copies out no file: the recipe's path inside the temporary directory, where nothing is written, or the error
    /// a test gives.
    func exportRecipeFile(of entry: RecipeEntry) throws -> URL {
        exportedEntries.append(entry)

        if let exportError {
            throw exportError
        }

        return URL.temporaryDirectory.appending(path: entry.id)
    }

    /// Yields recipes listed with no ingredient names, or a failure, to the stream, which keeps it until the stream is
    /// iterated.
    func send(_ result: Result<[RecipeEntry], Error>) {
        continuation.yield(result.map({ $0.map({ ListedRecipe(entry: $0, ingredientNames: []) }) }))
    }

    /// Yields recipes to the stream, which keeps them until the stream is iterated.
    func send(_ listedRecipes: [ListedRecipe]) {
        continuation.yield(.success(listedRecipes))
    }

    /// Ends the stream once the results already sent are iterated.
    func finish() {
        continuation.finish()
    }
}
