import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// The one recipe in a file outside the recipe directory, read where it sits through the file's own security scope and
/// fetched from iCloud where it is not on the device.
struct RecipeDocumentRepository: RecipeRepository {
    /// The recipe, found by the file's URL, which no recipe in a directory is found by.
    let entry: RecipeEntry

    let name: String

    private let parser: SousParser
    private let textReader: RecipeTextReader
    private let url: URL

    /// Creates a repository.
    ///
    /// - Parameters:
    ///   - url: The file, whose security scope every read opens.
    ///   - parser: What the recipe is read with.
    ///   - fileStatus: What the file system reports of the file at a URL, or of the file iCloud promises there.
    ///   - startDownloading: Asks iCloud for a file's contents, returning before they arrive.
    init(
        url: URL,
        parser: SousParser,
        fileStatus: @escaping @Sendable (URL) -> RecipeFileStatus? = RecipeFileStatus.read(at:),
        startDownloading: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    ) {
        let folder = RecipeDirectory(url: url.deletingLastPathComponent())
        let status = url.withSecurityScope({ fileStatus(url) })

        self.entry = RecipeEntry(
            id: url.absoluteString,
            name: RecipeEntry.name(forFileAt: url.lastPathComponent),
            availability: status?.downloadingStatus == .notDownloaded ? .notDownloaded : .downloaded
        )
        self.name = folder.name
        self.parser = parser
        // The folder's scope stays shut, and the file's own lets the reader through to the file.
        self.textReader = RecipeTextReader(
            recipeDirectory: folder,
            qualityOfService: .userInitiated,
            fileStatus: fileStatus,
            startDownloading: startDownloading
        )
        self.url = url
    }

    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[ListedRecipe], Error>.self)
        continuation.yield(.success([ListedRecipe(entry: entry, ingredientNames: [])]))

        return stream
    }

    func refresh() {}

    /// Reads off the caller's actor, where a recipe still in iCloud has to be fetched first.
    @concurrent
    func readRecipe(of _: RecipeEntry) async throws -> Parsed<Recipe> {
        let contents = try await url.withSecurityScope {
            try await textReader.read(path: url.lastPathComponent)
        }

        return parser.parseRecipe(contents.text)
    }

    /// Reads nothing: the file's scope reaches no picture beside it.
    func readThumbnail(of _: RecipePicture, filling _: CGSize) throws -> CGImage {
        throw CocoaError(.fileReadNoPermission)
    }

    func recipeID(forFileAt url: URL) -> String? {
        url.standardizedFileURL == self.url.standardizedFileURL ? entry.id : nil
    }

    /// Copies off the caller's actor, where a recipe still in iCloud has to be fetched first, into a folder of the
    /// copy's own under the temporary directory.
    @concurrent
    func exportRecipeFile(of _: RecipeEntry) async throws -> URL {
        try await url.withSecurityScope {
            try await textReader.copy(
                path: url.lastPathComponent,
                into: URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            )
        }
    }
}
