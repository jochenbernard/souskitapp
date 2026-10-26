import Foundation
@testable import MockRecipeLibrary
import Testing

extension MockRecipeRepositoryTests {
    @MainActor
    @Test("a recipe's file is exported holding its text, under its file's name")
    func exportRecipeFile() async throws {
        let repository = makeRepository()
        let brioche = try await currentRecipeEntry(withID: "Baking/brioche.sous", of: repository)

        let url = try await repository.exportRecipeFile(of: brioche)
        defer {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }

        #expect(url.lastPathComponent == "brioche.sous")
        #expect(try String(contentsOf: url, encoding: .utf8) == MockRecipes.brioche)
    }

    @MainActor
    @Test("the unreachable recipe fails to export")
    func unreachableRecipeFailsToExport() async throws {
        let repository = makeRepository()
        let unreachable = try await currentRecipeEntry(withID: "unreachable.sous", of: repository)

        await #expect(throws: CocoaError.self) {
            try await repository.exportRecipeFile(of: unreachable)
        }
    }
}
