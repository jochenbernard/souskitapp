import Foundation
@testable import MockRecipeLibrary
import RecipeLibrary
import SousKit
import Testing

@Suite("Mock recipe repository", .timeLimit(.minutes(1)))
struct MockRecipeRepositoryTests {
    private let parser = SousParser()

    @MainActor
    private func makeRepository() -> MockRecipeRepository {
        MockRecipeRepository(parser: parser, fetchDuration: .zero)
    }

    /// The first list a new stream from the repository yields, which is the recipes as they are now.
    @MainActor
    private func currentRecipeEntries(of repository: MockRecipeRepository) async throws -> [RecipeEntry] {
        var iterator = repository.recipeEntries().makeAsyncIterator()

        return try #require(await iterator.next()).get()
    }

    @MainActor
    private func currentRecipeEntry(
        withID id: String,
        of repository: MockRecipeRepository
    ) async throws -> RecipeEntry {
        try #require(try await currentRecipeEntries(of: repository).first(where: { $0.id == id }))
    }

    @Test("every recipe has a text to read but the unreachable one")
    func onlyTheUnreachableRecipeHasNoText() {
        #expect(MockRecipe.all.filter({ $0.text == nil }).map(\.id) == ["unreachable"])
    }

    @MainActor
    @Test("the recipes are listed by name, as a folder lists them")
    func listedByName() async throws {
        let names = try await currentRecipeEntries(of: makeRepository()).map(\.name)

        #expect(names == names.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }))
    }

    @MainActor
    @Test("every recipe with a text is listed with its summary, the ones in iCloud included")
    func summaries() async throws {
        let entries = try await currentRecipeEntries(of: makeRepository())

        #expect(entries.filter({ $0.summary == nil }).map(\.id) == ["unreachable"])
        #expect(entries.first(where: { $0.id == "crepes" })?.title == "Crepes")
        #expect(entries.first(where: { $0.id == "crepes" })?.availability == .notDownloaded)
        #expect(entries.first(where: { $0.id == "steps-only" })?.title == "steps only")
    }

    @MainActor
    @Test("every listed recipe reads but the unreachable one")
    func everyRecipeReads() async throws {
        let repository = makeRepository()

        for recipeEntry in try await currentRecipeEntries(of: repository) where recipeEntry.id != "unreachable" {
            _ = try await repository.readRecipe(of: recipeEntry)
        }
    }

    @MainActor
    @Test("a recipe in iCloud is listed as downloaded once it is read")
    func readRecipeComesDown() async throws {
        let repository = makeRepository()
        let crepes = try await currentRecipeEntry(withID: "crepes", of: repository)

        _ = try await repository.readRecipe(of: crepes)

        #expect(crepes.availability == .notDownloaded)
        #expect(try await currentRecipeEntry(withID: "crepes", of: repository).availability == .downloaded)
    }

    @MainActor
    @Test("a recipe on its way down lands without being read")
    func downloadingRecipeLands() async {
        let repository = makeRepository()
        var hasLanded = false

        // Waits for the landing, or for the suite's time limit to end the test.
        for await result in repository.recipeEntries()
        where (try? result.get())?.first(where: { $0.id == "gratin-dauphinois" })?.availability == .downloaded {
            hasLanded = true
            break
        }

        // Releasing the repository ends the stream, which would end the wait for nothing.
        withExtendedLifetime(repository, {})
        #expect(hasLanded)
    }

    @MainActor
    @Test("the unreachable recipe fails to read and stays in iCloud")
    func unreachableRecipeFails() async throws {
        let repository = makeRepository()
        let unreachable = try await currentRecipeEntry(withID: "unreachable", of: repository)

        await #expect(throws: CocoaError.self) {
            try await repository.readRecipe(of: unreachable)
        }
        #expect(try await currentRecipeEntry(withID: "unreachable", of: repository).availability == .notDownloaded)
    }

    @MainActor
    @Test("listing the recipes again ends the stream listed before")
    func secondStreamEndsTheFirst() async throws {
        let repository = makeRepository()
        let first = repository.recipeEntries()
        _ = repository.recipeEntries()

        // The loop ends only once the stream does; the suite's time limit fails a stream left running.
        var lists: [[RecipeEntry]] = []
        for await result in first {
            lists.append(try result.get())
        }

        #expect(!lists.isEmpty)
    }
}
