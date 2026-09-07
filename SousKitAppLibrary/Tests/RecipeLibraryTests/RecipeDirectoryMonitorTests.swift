import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory monitor", .timeLimit(.minutes(1)))
final class RecipeDirectoryMonitorTests: Sendable {
    private let directoryURL: URL

    init() throws {
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(path: "RecipeDirectoryMonitorTests.\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        self.directoryURL = url
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func writeFile(named fileName: String) throws {
        try Data().write(to: directoryURL.appending(path: fileName))
    }

    private func makeMonitor() -> RecipeDirectoryMonitor {
        RecipeDirectoryMonitor(
            recipeDirectory: RecipeDirectory(url: directoryURL),
            settleDelay: .milliseconds(20)
        )
    }

    /// Whether the monitor reaches the given names, reading on until it does or the suite's time
    /// limit ends the test.
    ///
    /// The monitor is taken as a parameter so that it outlives the stream it vends; a caller that
    /// released it would wait here for a list that never arrives.
    @MainActor
    private func names(
        reach expected: [String],
        from monitor: RecipeDirectoryMonitor,
        whileChanging change: () throws -> Void = {}
    ) async throws -> Bool {
        let stream = monitor.recipeFiles()
        try change()

        for await result in stream where (try? result.get())?.map(\.name) == expected {
            return true
        }

        return false
    }

    /// The first result the monitor reaches.
    @MainActor
    private func firstResult(
        from monitor: RecipeDirectoryMonitor
    ) async -> Result<[RecipeFile], Error>? {
        for await result in monitor.recipeFiles() {
            return result
        }

        return nil
    }

    @MainActor
    @Test("the recipes already there arrive first")
    func firstRead() async throws {
        try writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["Crepes"], from: makeMonitor())

        #expect(reached)
    }

    @MainActor
    @Test("an empty directory arrives as no recipes")
    func emptyDirectory() async throws {
        let reached = try await names(reach: [], from: makeMonitor())

        #expect(reached)
    }

    @MainActor
    @Test("a directory that is gone arrives as a failure")
    func failingRead() async throws {
        try FileManager.default.removeItem(at: directoryURL)

        let result = await firstResult(from: makeMonitor())

        #expect(throws: (any Error).self) {
            try #require(result).get()
        }
    }

    @MainActor
    @Test("a recipe added to the directory arrives")
    func addedRecipe() async throws {
        try writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["Brioche", "Crepes"], from: makeMonitor()) {
            try writeFile(named: "brioche.sous")
        }

        #expect(reached)
    }

    @MainActor
    @Test("a recipe removed from the directory stops arriving")
    func removedRecipe() async throws {
        try writeFile(named: "crepes.sous")
        try writeFile(named: "brioche.sous")

        let reached = try await names(reach: ["Crepes"], from: makeMonitor()) {
            try FileManager.default.removeItem(at: directoryURL.appending(path: "brioche.sous"))
        }

        #expect(reached)
    }

    @MainActor
    @Test("a recipe renamed in the directory arrives under the new name")
    func renamedRecipe() async throws {
        try writeFile(named: "crepes.sous")

        let reached = try await names(reach: ["Crepes Suzette"], from: makeMonitor()) {
            try FileManager.default.moveItem(
                at: directoryURL.appending(path: "crepes.sous"),
                to: directoryURL.appending(path: "crepes-suzette.sous")
            )
        }

        #expect(reached)
    }

    @MainActor
    @Test("refreshing reaches the recipes written since the last read")
    func refreshing() async throws {
        let monitor = makeMonitor()

        let reached = try await names(reach: ["Crepes"], from: monitor) {
            try writeFile(named: "crepes.sous")
            monitor.refresh()
        }

        #expect(reached)
    }

    @MainActor
    @Test("a second stream ends the first")
    func secondStream() async throws {
        let monitor = makeMonitor()
        let first = monitor.recipeFiles()

        let reached = try await names(reach: [], from: monitor)

        var firstResults: [Result<[RecipeFile], Error>] = []
        for await result in first {
            firstResults.append(result)
        }

        #expect(reached)
        #expect(firstResults.isEmpty)
    }
}
