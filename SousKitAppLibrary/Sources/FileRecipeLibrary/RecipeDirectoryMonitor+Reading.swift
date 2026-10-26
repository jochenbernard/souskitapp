import Foundation
import RecipeLibrary

extension RecipeDirectoryMonitor {
    /// Reads off the main actor, where a directory in iCloud can take a while to answer.
    @concurrent
    nonisolated static func readListing(
        with listDirectory: @Sendable () throws -> RecipeDirectoryListing
    ) async -> Result<RecipeDirectoryListing, Error> {
        Result(catching: listDirectory)
    }

    /// Yields the recipes with the summaries the cache holds, then reads those it has none for, yielding the recipes
    /// again as they land.
    ///
    /// The files on the device are read together. Holding no monitor, it leaves a released one free to go.
    ///
    /// - Parameter fetch: Fetches the files in iCloud among those handed to it, returning the files on the device
    ///   that no fetch reads.
    static func readSummaries(
        of listing: RecipeDirectoryListing,
        with summarizer: RecipeSummarizer,
        yield: @escaping @MainActor ([ListedRecipe]) -> Void,
        fetch: @MainActor ([RecipeFile]) -> [RecipeFile]
    ) async {
        let yieldSummaries = {
            let listedRecipes = await summarizer.listedRecipes(for: listing.recipeFiles, pictures: listing.pictures)

            if !Task.isCancelled {
                yield(listedRecipes)
            }
        }

        await yieldSummaries()

        let filesToRead = await summarizer.filesToRead(in: listing.recipeFiles)

        guard !Task.isCancelled else {
            return
        }

        let filesOnDevice = fetch(filesToRead)

        if !filesOnDevice.isEmpty {
            await summarizer.read(filesOnDevice)
            await yieldSummaries()
        }
    }
}
