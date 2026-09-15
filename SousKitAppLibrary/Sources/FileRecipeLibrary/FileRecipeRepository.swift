import RecipeLibrary
import SousKit

/// The recipes sitting directly in a directory, fetched from iCloud where they are not on the device.
struct FileRecipeRepository: RecipeRepository {
    private let parser = SousParser()

    private let monitor: RecipeDirectoryMonitor
    private let recipeDirectory: RecipeDirectory
    private let textReader: RecipeTextReader

    var name: String {
        recipeDirectory.name
    }

    init(recipeDirectory: RecipeDirectory) {
        self.monitor = RecipeDirectoryMonitor(recipeDirectory: recipeDirectory)
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
