import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// The recipes in a directory and in the directories inside it, fetched from iCloud where they are not on the device,
/// each with the symbol picked for it.
struct FileRecipeRepository: RecipeRepository {
    private let monitor: RecipeDirectoryMonitor
    private let parser: SousParser
    private let pictureReader: RecipePictureReader
    private let recipeDirectory: RecipeDirectory
    private let symbolQueue: RecipeSymbolQueue
    private let textReader: RecipeTextReader
    private let thumbnailCache: RecipeThumbnailCache

    var name: String {
        recipeDirectory.name
    }

    /// Creates a repository.
    ///
    /// - Parameters:
    ///   - parser: What the recipes are read with.
    ///   - recipeDirectory: The directory the recipes sit in.
    ///   - symbolPicker: What the recipes' symbols are picked with.
    ///   - summaryCacheURL: Where the recipes' summaries are kept between launches, outside the directory.
    ///   - thumbnailCacheURL: Where the thumbnails of the recipes' pictures are kept, outside the directory.
    ///   - fileStatus: What the file system reports of the file at a URL, or of the file iCloud promises there.
    ///   - startDownloading: Asks iCloud for a file's contents, returning before they arrive.
    init(
        parser: SousParser,
        recipeDirectory: RecipeDirectory,
        symbolPicker: RecipeSymbolPicker,
        summaryCacheURL: URL,
        thumbnailCacheURL: URL,
        fileStatus: @escaping @Sendable (URL) -> RecipeFileStatus? = RecipeFileStatus.read(at:),
        startDownloading: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    ) {
        let cache = RecipeThumbnailCache(recipeDirectory: recipeDirectory, folderURL: thumbnailCacheURL)
        let summarizer = RecipeSummarizer(
            cache: RecipeSummaryCache(recipeDirectory: recipeDirectory, fileURL: summaryCacheURL),
            parser: parser,
            textReader: RecipeTextReader(
                recipeDirectory: recipeDirectory,
                qualityOfService: .utility,
                fileStatus: fileStatus,
                startDownloading: startDownloading
            )
        )
        self.monitor = RecipeDirectoryMonitor(
            recipeDirectory: recipeDirectory,
            summarizer: summarizer,
            thumbnailCache: cache,
            fileStatus: fileStatus,
            startDownloadingPicture: startDownloading
        )
        self.parser = parser
        self.pictureReader = RecipePictureReader(
            recipeDirectory: recipeDirectory,
            qualityOfService: .userInitiated,
            fileStatus: fileStatus,
            startDownloading: startDownloading
        )
        self.recipeDirectory = recipeDirectory
        self.symbolQueue = RecipeSymbolQueue(picker: symbolPicker) { path, symbolPick in
            await summarizer.keep(symbolPick, forRecipeAt: path)
        }
        self.textReader = RecipeTextReader(
            recipeDirectory: recipeDirectory,
            qualityOfService: .userInitiated,
            fileStatus: fileStatus,
            startDownloading: startDownloading
        )
        self.thumbnailCache = cache
    }

    func listedRecipes() async -> AsyncStream<Result<[ListedRecipe], Error>> {
        await symbolQueue.listedRecipes(following: monitor.listedRecipes())
    }

    func refresh() async {
        await monitor.refresh()
    }

    /// Reads off the caller's actor, where a recipe still in iCloud has to be fetched first.
    @concurrent
    func readRecipe(of entry: RecipeEntry) async throws -> Parsed<Recipe> {
        let contents = try await textReader.read(path: entry.path)

        return parser.parseRecipe(contents.text)
    }

    /// Reads and scales off the caller's actor, from the thumbnail kept where there is one; one is made for the kept
    /// size holding the box.
    @concurrent
    func readThumbnail(of picture: RecipePicture, filling pixelSize: CGSize) async throws -> CGImage {
        if let thumbnail = thumbnailCache.thumbnail(of: picture, filling: pixelSize) {
            return thumbnail
        }

        let keptSize = RecipeThumbnailCache.keptSize(holding: pixelSize)
        let keptThumbnail = try await pictureReader.read(picture) { url in
            try RecipeThumbnailMaker.thumbnail(ofImageAt: url, filling: keptSize)
        }
        thumbnailCache.save(
            keptThumbnail,
            of: picture,
            filling: pixelSize
        )

        // Read back from the kept file, so the first read shows the picture as every later one does.
        return thumbnailCache.thumbnail(of: picture, filling: pixelSize) ?? keptThumbnail
    }

    /// Copies off the caller's actor, where a recipe still in iCloud has to be fetched first, into a folder of the
    /// copy's own under the temporary directory.
    @concurrent
    func exportRecipeFile(of entry: RecipeEntry) async throws -> URL {
        try await textReader.copy(
            path: entry.path,
            into: URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        )
    }
}
