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

    // With no presenter: on a simulator a presenter hears writes made without file coordination, on a device not.
    @MainActor
    @Test("a recipe written into a new directory between its listing and its watch arrives")
    func recipeWrittenWhileANewDirectoryIsListed() async throws {
        try directory.writeFile(named: "crepes.sous")
        let listingSpy = ListingSpy(changingAfterListing: "Baking") {
            try self.directory.writeFile(named: "Baking/madeleines.sous")
        }
        let monitor = makeMonitor(listingSpy: listingSpy, presentsDirectory: false)

        let reached = try await names(
            reach: ["madeleines", "crepes"],
            from: monitor,
            afterListing: [{ try self.directory.makeDirectory(named: "Baking") }]
        )

        #expect(reached)
    }

    @MainActor
    @Test("a read finding no directory it did not watch lists once")
    func listingWithoutNewDirectory() async throws {
        try directory.writeFile(named: "crepes.sous")
        let listingSpy = ListingSpy()
        let monitor = makeMonitor(listingSpy: listingSpy)

        let reached = try await names(
            reach: ["crepes"],
            from: monitor,
            afterListing: []
        )

        #expect(reached)
        #expect(listingSpy.count == 1)
    }

    @MainActor
    @Test("a read finding a directory it did not watch lists again once watching it")
    func listingWithNewDirectory() async throws {
        try directory.makeDirectory(named: "Baking")
        try directory.writeFile(named: "Baking/madeleines.sous")
        let listingSpy = ListingSpy()
        let monitor = makeMonitor(listingSpy: listingSpy)

        let reached = try await names(
            reach: ["madeleines"],
            from: monitor,
            afterListing: []
        )

        #expect(reached)
        #expect(listingSpy.count == 2)
    }
}
