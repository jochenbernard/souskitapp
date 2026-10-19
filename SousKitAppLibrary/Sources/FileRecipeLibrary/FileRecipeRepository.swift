import Foundation
import RecipeLibrary
import SousKit

/// The recipes sitting directly in a directory, fetched from iCloud where they are not on the device.
struct FileRecipeRepository: RecipeRepository {
    private let monitor: RecipeDirectoryMonitor
    private let parser: SousParser
    private let recipeDirectory: RecipeDirectory
    private let textReader: RecipeTextReader

    var name: String {
        recipeDirectory.name
    }

    /// Creates a repository.
    ///
    /// - Parameters:
    ///   - parser: What the recipes are read with.
    ///   - recipeDirectory: The directory the recipes sit in.
    ///   - summaryCacheURL: Where the recipes' summaries are kept between launches, outside the directory.
    init(
        parser: SousParser,
        recipeDirectory: RecipeDirectory,
        summaryCacheURL: URL
    ) {
        self.monitor = RecipeDirectoryMonitor(
            recipeDirectory: recipeDirectory,
            summarizer: RecipeSummarizer(
                recipeDirectory: recipeDirectory,
                cache: RecipeSummaryCache(recipeDirectory: recipeDirectory, fileURL: summaryCacheURL),
                parser: parser
            )
        )
        self.parser = parser
        self.recipeDirectory = recipeDirectory
        self.textReader = RecipeTextReader(recipeDirectory: recipeDirectory)
    }

    func recipeEntries() async -> AsyncStream<Result<[RecipeEntry], Error>> {
        await monitor.recipeEntries()
    }

    func refresh() async {
        await monitor.refresh()
    }

    /// Reads off the caller's actor, where a recipe still in iCloud has to be fetched first.
    @concurrent
    func readRecipe(of entry: RecipeEntry) async throws -> Parsed<Recipe> {
        let text = try textReader.readText(of: entry)

        return parser.parseRecipe(text)
    }
}
