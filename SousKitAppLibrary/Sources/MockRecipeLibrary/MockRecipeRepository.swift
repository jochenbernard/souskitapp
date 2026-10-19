import Foundation
import RecipeLibrary
import SousKit

/// Recipes kept in the app, for trying it where no folder can be picked, such as on a simulator.
///
/// They sit in folders as a folder's recipes do, some of them sharing a file name. Some of the recipes start out in
/// iCloud, and reading one fetches it first, as a folder in iCloud Drive does. One of them never arrives. Every recipe
/// with a text is listed with its summary, as a folder lists the recipes it read on an earlier launch.
@MainActor
public final class MockRecipeRepository: RecipeRepository {
    private let fetchDuration: Duration
    private let parser: SousParser
    private let summaries: [String: RecipeSummary]

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
        self.summaries = MockRecipe.all.reduce(into: [:]) { summaries, recipe in
            summaries[recipe.id] = recipe.text.map { text in
                RecipeSummary(recipe: parser.parseRecipe(text).value, parser: parser)
            }
        }
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
        guard let recipe = MockRecipe.all.first(where: { $0.isListed && $0.id == entry.id }) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        if availability(of: recipe) != .downloaded {
            try await Task.sleep(for: fetchDuration)
        }

        guard let text = recipe.text else {
            throw CocoaError(.ubiquitousFileUbiquityServerNotAvailable)
        }

        markFetched([recipe])

        return parser.parseRecipe(text)
    }

    private var entries: [RecipeEntry] {
        MockRecipe.all.filter(\.isListed).map { recipe in
            RecipeEntry(
                id: recipe.id,
                name: recipe.name,
                availability: availability(of: recipe),
                summary: summaries[recipe.id],
                folderPath: recipe.folderPath
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

    /// Marks recipes as come down from iCloud, telling the stream where that changes what it lists.
    private func markFetched(_ recipes: [MockRecipe]) {
        let ids = Set(recipes.filter({ $0.availability != .downloaded }).map(\.id))

        guard !ids.isSubset(of: fetchedIDs) else {
            return
        }

        fetchedIDs.formUnion(ids)
        continuation?.yield(.success(entries))
    }
}
