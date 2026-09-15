import RecipeLibrary
import SousKit

/// A repository listing whatever a test sends it, counting its refreshes.
@MainActor
final class RecipeRepositorySpy: RecipeRepository {
    nonisolated let name = "Recipes"

    private(set) var refreshCount = 0

    nonisolated private let parser = SousParser()

    private let continuation: AsyncStream<Result<[RecipeEntry], Error>>.Continuation
    private let stream: AsyncStream<Result<[RecipeEntry], Error>>

    init() {
        (self.stream, self.continuation) = AsyncStream.makeStream(of: Result<[RecipeEntry], Error>.self)
    }

    func recipeEntries() -> AsyncStream<Result<[RecipeEntry], Error>> {
        stream
    }

    func refresh() {
        refreshCount += 1
    }

    nonisolated func readRecipe(of _: RecipeEntry) -> Parsed<Recipe> {
        parser.parseRecipe("")
    }

    /// Yields a result to the stream, which keeps it until the stream is iterated.
    func send(_ result: Result<[RecipeEntry], Error>) {
        continuation.yield(result)
    }
}
