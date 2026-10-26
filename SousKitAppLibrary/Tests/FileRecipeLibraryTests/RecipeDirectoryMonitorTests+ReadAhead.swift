@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Synchronization
import Testing

extension RecipeDirectoryMonitorTests {
    @MainActor
    @Test("a stream after a read ahead yields the recipes listed ahead, then reads the directory itself")
    func streamAfterReadAhead() async throws {
        try directory.writeFile(named: "crepes.sous")
        let listingCount = Mutex(0)
        let monitor = RecipeDirectoryMonitor(
            recipeDirectory: directory.recipeDirectory,
            summarizer: RecipeSummarizer(
                cache: directory.summaryCache,
                parser: SousParser(),
                textReader: RecipeTextReader(recipeDirectory: directory.recipeDirectory, qualityOfService: .utility)
            ),
            settleDelay: .milliseconds(20),
            listDirectory: { reader in
                let isFirst = listingCount.withLock { count in
                    count += 1

                    return count == 1
                }

                // The read ahead lists, and the stream's own read fails, so each result tells which read it came from.
                guard isFirst else {
                    throw CocoaError(.fileReadUnknown)
                }

                return try reader.readListing()
            }
        )

        monitor.readAhead()
        var results = monitor.listedRecipes().makeAsyncIterator()
        let first = await results.next(isolation: #isolation)
        let second = await results.next(isolation: #isolation)

        #expect(try #require(first).get().map(\.entry.name) == ["crepes"])
        #expect(throws: (any Error).self) {
            try #require(second).get()
        }
    }
}
