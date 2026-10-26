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
        let monitor = makeReadAheadMonitor {
            listingCount.withLock { count in
                count += 1

                return count == 1
            }
        }

        monitor.readAhead()
        var results = monitor.listedRecipes().makeAsyncIterator()
        let first = await results.next(isolation: #isolation)
        let second = await results.next(isolation: #isolation)

        #expect(try #require(first).get().map(\.entry.name) == ["crepes"])
        #expect(throws: (any Error).self) {
            try #require(second).get()
        }
    }

    @MainActor
    @Test("a read started while the read ahead lists waits for it, yielding the recipes listed ahead first")
    func readDuringReadAhead() async throws {
        try directory.writeFile(named: "crepes.sous")
        let listingCount = Mutex(0)
        let readAheadGate = DispatchSemaphore(value: 0)
        let monitor = makeReadAheadMonitor(readAheadGate: readAheadGate) {
            listingCount.withLock { count in
                count += 1

                return count == 1
            }
        }

        monitor.readAhead()

        while listingCount.withLock({ $0 }) == 0 {
            try await Task.sleep(for: .milliseconds(1))
        }

        var results = monitor.listedRecipes().makeAsyncIterator()
        monitor.refresh()
        readAheadGate.signal()
        let first = await results.next(isolation: #isolation)

        #expect(try #require(first).get().map(\.entry.name) == ["crepes"])
    }

    /// A monitor whose first listing, the read ahead's, succeeds once `readAheadGate` opens, and whose later listings
    /// fail, so each result tells which read it came from.
    ///
    /// - Parameter isFirstListing: Counts a listing, returning whether it is the first.
    private func makeReadAheadMonitor(
        readAheadGate: DispatchSemaphore? = nil,
        isFirstListing: @escaping @Sendable () -> Bool
    ) -> RecipeDirectoryMonitor {
        RecipeDirectoryMonitor(
            recipeDirectory: directory.recipeDirectory,
            summarizer: RecipeSummarizer(
                cache: directory.summaryCache,
                parser: SousParser(),
                textReader: RecipeTextReader(recipeDirectory: directory.recipeDirectory, qualityOfService: .utility)
            ),
            settleDelay: .milliseconds(20),
            listDirectory: { reader in
                guard isFirstListing() else {
                    throw CocoaError(.fileReadUnknown)
                }

                readAheadGate?.wait()

                return try reader.readListing()
            }
        )
    }
}
