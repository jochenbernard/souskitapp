import CoreGraphics
import Foundation
import RecipeLibrary
import SousKit

/// Recipes kept in the app, for trying it where no folder can be picked, such as on a simulator.
///
/// They sit in folders as a folder's recipes do, some of them sharing a file name. Some of the recipes start out in
/// iCloud, and reading one fetches it first, as a folder in iCloud Drive does. One of them never arrives. Every recipe
/// with a text is listed with its summary and ingredient names, as a folder lists the recipes it read on an earlier
/// launch, and with the picture its header names where the folder holds it. A picture in iCloud lands a fetch's time
/// after the recipes are first listed. Symbols are picked and kept between launches as a folder's are.
@MainActor
public final class MockRecipeRepository: RecipeRepository {
    private let fetchDuration: Duration
    private let parser: SousParser
    // By path, so listing many recipes looks each one's picture up at once.
    private let pictureFiles: [String: MockRecipe]
    private let summaries: [String: RecipeSummary]
    private let ingredientNames: [String: [String]]
    // By recipe id, as an earlier launch kept them.
    private let symbolPicks: [String: RecipeSymbolPick]
    private let symbolQueue: RecipeSymbolQueue

    private var continuation: AsyncStream<Result<[ListedRecipe], Error>>.Continuation?
    private var downloadTask: Task<Void, Never>?
    private var fetchedIDs: Set<String> = []

    nonisolated public var name: String {
        String(localized: "Mock recipes", bundle: .module)
    }

    /// Creates a repository.
    ///
    /// - Parameters:
    ///   - parser: What the recipes are read with.
    ///   - symbolPicker: What the recipes' symbols are picked with.
    ///   - symbolCacheURL: Where the recipes' symbols are kept between launches.
    ///   - fetchDuration: How long a recipe takes to come down from iCloud.
    nonisolated public init(
        parser: SousParser,
        symbolPicker: RecipeSymbolPicker,
        symbolCacheURL: URL,
        fetchDuration: Duration = .seconds(3)
    ) {
        let symbolCache = MockSymbolCache(fileURL: symbolCacheURL)

        self.parser = parser
        self.symbolPicks = symbolCache.load()
        self.symbolQueue = RecipeSymbolQueue(picker: symbolPicker) { id, symbolPick in
            symbolCache.keep(symbolPick, forRecipeWithID: id)
        }
        self.fetchDuration = fetchDuration
        self.pictureFiles = Dictionary(
            uniqueKeysWithValues: MockRecipe.all.filter(\.isPicture).map({ ($0.id, $0) })
        )
        let recipes = MockRecipe.all.reduce(into: [String: Recipe]()) { recipes, mockRecipe in
            recipes[mockRecipe.id] = mockRecipe.text.map({ parser.parseRecipe($0).value })
        }
        self.summaries = recipes.mapValues({ RecipeSummary(recipe: $0, parser: parser) })
        self.ingredientNames = recipes.mapValues(\.foodIngredientNames)
    }

    deinit {
        downloadTask?.cancel()
        continuation?.finish()
    }

    public func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        continuation?.finish()

        let (stream, streamContinuation) = AsyncStream.makeStream(
            of: Result<[ListedRecipe], Error>.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation = streamContinuation
        streamContinuation.yield(.success(listing))
        finishDownloads()

        return symbolQueue.listedRecipes(following: stream)
    }

    public func refresh() {}

    @MainActor
    public func readThumbnail(of picture: RecipePicture, filling pixelSize: CGSize) async throws -> CGImage {
        guard let file = pictureFiles[picture.id] else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        if availability(of: file) != .downloaded {
            try await Task.sleep(for: fetchDuration)
            markFetched([file])
        }

        guard let mockPicture = file.picture else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return try await Self.draw(mockPicture, filling: pixelSize)
    }

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

    private var listing: [ListedRecipe] {
        MockRecipe.all.filter(\.isListed).map { recipe in
            ListedRecipe(
                entry: RecipeEntry(
                    id: recipe.id,
                    name: recipe.name,
                    availability: availability(of: recipe),
                    summary: summaries[recipe.id],
                    folderPath: recipe.folderPath,
                    picture: picture(of: recipe)
                ),
                ingredientNames: ingredientNames[recipe.id] ?? [],
                symbolPick: symbolPicks[recipe.id]
            )
        }
    }

    /// The picture a recipe's header names, where the folder holds a file there.
    private func picture(of recipe: MockRecipe) -> RecipePicture? {
        guard
            let path = summaries[recipe.id]?.imagePath(inFolder: recipe.folderPath),
            let file = pictureFiles[path]
        else {
            return nil
        }

        return RecipePicture(
            id: file.id,
            modificationDate: nil,
            availability: availability(of: file)
        )
    }

    /// Draws off the main actor, as decoding a photo would be.
    @concurrent
    nonisolated private static func draw(_ picture: MockPicture, filling pixelSize: CGSize) async throws -> CGImage {
        try picture.thumbnail(filling: pixelSize)
    }

    private func availability(of recipe: MockRecipe) -> RecipeAvailability {
        fetchedIDs.contains(recipe.id) ? .downloaded : recipe.availability
    }

    /// Lands the recipes already on their way down, and the pictures in iCloud, a fetch's time after the recipes are
    /// first listed.
    private func finishDownloads() {
        guard downloadTask == nil else {
            return
        }

        downloadTask = Task { [weak self, fetchDuration] in
            try? await Task.sleep(for: fetchDuration)
            self?.markFetched(MockRecipe.all.filter({ $0.availability == .downloading || $0.isPicture }))
        }
    }

    /// Marks recipes as come down from iCloud, telling the stream where that changes what it lists.
    private func markFetched(_ recipes: [MockRecipe]) {
        let ids = Set(recipes.filter({ $0.availability != .downloaded }).map(\.id))

        guard !ids.isSubset(of: fetchedIDs) else {
            return
        }

        fetchedIDs.formUnion(ids)
        continuation?.yield(.success(listing))
    }
}
