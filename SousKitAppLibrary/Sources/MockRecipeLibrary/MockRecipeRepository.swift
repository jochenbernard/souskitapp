import Foundation
import RecipeLibrary
import SousKit

/// Recipes kept in the app, for trying it where no folder can be picked, such as on a simulator.
///
/// Some of the recipes start out in iCloud, and reading one fetches it first, as a folder in iCloud Drive does. One
/// of them never arrives.
@MainActor
public final class MockRecipeRepository: RecipeRepository {
    private let fetchDuration: Duration
    private let parser: SousParser

    private var continuation: AsyncStream<Result<[RecipeEntry], Error>>.Continuation?
    private var downloadTask: Task<Void, Never>?
    private var fetchedIDs: Set<String> = []

    nonisolated public var name: String {
        String(localized: "Mock recipes", bundle: .module)
    }

    /// Creates a repository.
    ///
    /// - Parameters:
    ///   - parser: What the recipes are read with.
    ///   - fetchDuration: How long a recipe takes to come down from iCloud.
    nonisolated public init(
        parser: SousParser,
        fetchDuration: Duration = .seconds(3)
    ) {
        self.parser = parser
        self.fetchDuration = fetchDuration
    }

    deinit {
        downloadTask?.cancel()
        continuation?.finish()
    }

    public func recipeEntries() -> AsyncStream<Result<[RecipeEntry], Error>> {
        continuation?.finish()

        let (stream, streamContinuation) = AsyncStream.makeStream(
            of: Result<[RecipeEntry], Error>.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation = streamContinuation
        streamContinuation.yield(.success(entries))
        finishDownloads()

        return stream
    }

    public func refresh() {}

    @MainActor
    public func readRecipe(of entry: RecipeEntry) async throws -> Parsed<Recipe> {
        guard let recipe = MockRecipe.all.first(where: { $0.id == entry.id }) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        if availability(of: recipe) != .downloaded {
            try await Task.sleep(for: fetchDuration)

            if recipe.isUnreachable {
                throw CocoaError(.ubiquitousFileUbiquityServerNotAvailable)
            }

            markFetched([recipe])
        }

        return parser.parseRecipe(try recipe.text())
    }

    private var entries: [RecipeEntry] {
        MockRecipe.all.map { recipe in
            RecipeEntry(
                id: recipe.id,
                name: recipe.name,
                availability: availability(of: recipe)
            )
        }
    }

    private func availability(of recipe: MockRecipe) -> RecipeAvailability {
        fetchedIDs.contains(recipe.id) ? .downloaded : recipe.availability
    }

    /// Lands the recipes already on their way down a fetch's time after the recipes are first listed.
    private func finishDownloads() {
        guard downloadTask == nil else {
            return
        }

        downloadTask = Task { [weak self, fetchDuration] in
            try? await Task.sleep(for: fetchDuration)
            self?.markFetched(MockRecipe.all.filter({ $0.availability == .downloading }))
        }
    }

    private func markFetched(_ recipes: [MockRecipe]) {
        fetchedIDs.formUnion(recipes.map(\.id))
        continuation?.yield(.success(entries))
    }
}
