@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import Testing

extension RecipeDirectoryMonitorTests {
    /// Whether the monitor reaches the given names, making the changes in turn once it has first listed the directory,
    /// each a while after the one before, so a change lands in a directory already watched.
    @MainActor
    private func names(
        reach expected: [String],
        from monitor: RecipeDirectoryMonitor,
        afterListing changes: [() throws -> Void]
    ) async throws -> Bool {
        let stream = monitor.recipeEntries()
        var pending = changes[...]

        for await result in stream {
            if (try? result.get())?.map(\.name) == expected {
                return true
            }

            // Each change after the first waits out the read of the directory the one before sets off.
            while let change = pending.popFirst() {
                try change()

                if !pending.isEmpty {
                    try await Task.sleep(for: .milliseconds(300))
                }
            }
        }

        return false
    }

    @MainActor
    @Test("a recipe added to a directory inside arrives, at any depth")
    func addedNestedRecipe() async throws {
        try directory.makeDirectory(named: "French/Comfort food")
        try directory.writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["crepes", "gratin dauphinois"], from: makeMonitor(), afterListing: [
            { try self.directory.writeFile(named: "French/Comfort food/gratin-dauphinois.sous") }
        ])

        #expect(reached)
    }

    @MainActor
    @Test("a recipe written through file coordination into a directory inside arrives")
    func coordinatedNestedRecipe() async throws {
        try directory.makeDirectory(named: "Baking")
        let url = directory.url.appending(path: "Baking/brioche.sous")

        let reached = try await names(reach: ["brioche"], from: makeMonitor(), afterListing: [
            {
                var coordinationError: NSError?
                NSFileCoordinator().coordinate(
                    writingItemAt: url,
                    options: [],
                    error: &coordinationError
                ) { writingURL in
                    try? Data().write(to: writingURL)
                }

                if let coordinationError {
                    throw coordinationError
                }
            }
        ])

        #expect(reached)
    }

    @MainActor
    @Test("a recipe added to a directory made after the first read arrives")
    func recipeInANewDirectory() async throws {
        try directory.writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["madeleines", "crepes"], from: makeMonitor(), afterListing: [
            { try self.directory.makeDirectory(named: "Baking") },
            { try self.directory.writeFile(named: "Baking/madeleines.sous") }
        ])

        #expect(reached)
    }
}
