/// Follows a repository's recipes and picks the symbols they are missing, one at a time in the background while symbols
/// can be picked, listing the recipes again with each pick as it lands.
///
/// A recipe is picked for where its contents have been read and its summary holds no pick made from what it says now,
/// those without a picture first. A pick that fails is not asked for again until its input changes or picking becomes
/// possible again after it was not. Picks are kept as long as the queue is, and handed on to be kept longer.
@MainActor
public final class RecipeSymbolQueue {
    private typealias Listing = Result<[ListedRecipe], Error>

    private struct Request: Hashable {
        let id: String
        let input: RecipeSymbolInput
    }

    private let picker: RecipeSymbolPicker
    private let save: (@MainActor (String, RecipeSymbolPick) async -> Void)?

    private var availabilityTask: Task<Void, Never>?
    private var continuation: AsyncStream<Listing>.Continuation?
    private var failedRequests: Set<Request> = []
    private var generation = 0
    private var isAvailable = false
    // What the stream followed sent last, or `nil` where none is followed.
    private var listing: Listing?
    private var pickTask: Task<Void, Never>?
    // By recipe id.
    private var picks: [String: RecipeSymbolPick] = [:]
    private var requests: [Request] = []

    /// Creates a queue, which picks nothing until it follows a stream.
    ///
    /// - Parameters:
    ///   - picker: What the symbols are picked with.
    ///   - save: Keeps a pick beyond the queue, for the recipe with the id, before the next pick is asked for, or
    ///     `nil` where picks last as long as the queue.
    nonisolated public init(
        picker: RecipeSymbolPicker,
        save: (@MainActor (String, RecipeSymbolPick) async -> Void)? = nil
    ) {
        self.picker = picker
        self.save = save
    }

    deinit {
        availabilityTask?.cancel()
        pickTask?.cancel()
    }

    /// The recipes a stream yields, each with the symbol picked last for it, yielded again each time a pick lands.
    ///
    /// The stream ends where the one it follows does, and cancelling the task iterating it ends both. Picking follows
    /// the stream returned last, and stops once it ends.
    ///
    /// - Parameter upstream: The stream from the repository's ``RecipeRepository/listedRecipes()``.
    /// - Returns: The stream.
    public func listedRecipes(
        following upstream: AsyncStream<Result<[ListedRecipe], Error>>
    ) -> AsyncStream<Result<[ListedRecipe], Error>> {
        let (stream, streamContinuation) = AsyncStream.makeStream(
            of: Listing.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        generation += 1
        continuation = streamContinuation
        let followed = generation

        let task = Task { [weak self] in
            for await received in upstream {
                self?.receive(received, at: followed, into: streamContinuation)
            }

            streamContinuation.finish()
            self?.stopFollowing(at: followed)
        }
        streamContinuation.onTermination = { _ in
            task.cancel()
        }

        return stream
    }

    private func receive(
        _ listing: Listing,
        at generation: Int,
        into streamContinuation: AsyncStream<Listing>.Continuation
    ) {
        // A stream already replaced still sends on what it was sent, but no longer decides what is picked.
        guard generation == self.generation else {
            streamContinuation.yield(listing.map(withPicks))
            return
        }

        let picked = listing.map(withPicks)
        self.listing = listing
        streamContinuation.yield(picked)
        requests = Self.requests(for: (try? picked.get()) ?? [], promptVersion: picker.promptVersion)
        watchAvailability()
        startPicking()
    }

    private func stopFollowing(at generation: Int) {
        guard generation == self.generation else {
            return
        }

        continuation = nil
        listing = nil
        requests = []
    }

    /// The recipes, each with the pick made here in place of its summary's, where this one is current and that one not.
    private func withPicks(_ listedRecipes: [ListedRecipe]) -> [ListedRecipe] {
        guard !picks.isEmpty else {
            return listedRecipes
        }

        let promptVersion = picker.promptVersion

        return listedRecipes.map { listedRecipe in
            let entry = listedRecipe.entry

            guard
                let pick = picks[entry.id],
                let summary = entry.summary,
                let input = RecipeSymbolInput(listedRecipe: listedRecipe),
                summary.symbolPick?.isCurrent(for: input, promptVersion: promptVersion) != true,
                pick.isCurrent(for: input, promptVersion: promptVersion)
            else {
                return listedRecipe
            }

            var pickedSummary = summary
            pickedSummary.symbolPick = pick

            return ListedRecipe(
                entry: RecipeEntry(
                    id: entry.id,
                    name: entry.name,
                    availability: entry.availability,
                    summary: pickedSummary,
                    folderPath: entry.folderPath,
                    picture: entry.picture
                ),
                ingredientNames: listedRecipe.ingredientNames
            )
        }
    }

    /// What has to be picked for the recipes: those whose summaries hold no current pick.
    private static func requests(for listedRecipes: [ListedRecipe], promptVersion: Int) -> [Request] {
        var withoutPicture: [Request] = []
        var withPicture: [Request] = []

        for listedRecipe in listedRecipes {
            guard
                let input = RecipeSymbolInput(listedRecipe: listedRecipe),
                listedRecipe.entry.summary?.symbolPick?.isCurrent(for: input, promptVersion: promptVersion) != true
            else {
                continue
            }

            let request = Request(id: listedRecipe.entry.id, input: input)

            if listedRecipe.entry.picture == nil {
                withoutPicture.append(request)
            } else {
                withPicture.append(request)
            }
        }

        // A card with a picture shows its symbol only until the picture is read.
        return withoutPicture + withPicture
    }

    private func watchAvailability() {
        guard availabilityTask == nil else {
            return
        }

        availabilityTask = Task { [weak self, picker] in
            for await canPick in picker.availabilityUpdates() {
                self?.didChangeAvailability(canPick)
            }
        }
    }

    private func didChangeAvailability(_ isAvailable: Bool) {
        // What failed while picking was becoming impossible is asked for again once it is possible.
        if isAvailable, !self.isAvailable {
            failedRequests = []
        }

        self.isAvailable = isAvailable
        startPicking()
    }

    private func startPicking() {
        guard pickTask == nil, nextRequest != nil else {
            return
        }

        pickTask = Task { [weak self, picker] in
            while !Task.isCancelled, let request = self?.nextRequest {
                let symbol = try? await picker.symbol(for: request.input)

                guard !Task.isCancelled else {
                    return
                }

                await self?.finish(request, symbol: symbol)
            }

            if !Task.isCancelled {
                self?.pickTask = nil
            }
        }
    }

    private var nextRequest: Request? {
        guard isAvailable else {
            return nil
        }

        return requests.first(where: { !failedRequests.contains($0) })
    }

    private func finish(_ request: Request, symbol: String?) async {
        // A failed request stays, for when picking becomes possible again.
        guard let symbol else {
            failedRequests.insert(request)
            return
        }

        requests.removeAll(where: { $0 == request })

        let pick = RecipeSymbolPick(
            symbol: symbol,
            input: request.input,
            promptVersion: picker.promptVersion
        )
        picks[request.id] = pick

        if let listing {
            continuation?.yield(listing.map(withPicks))
        }

        await save?(request.id, pick)
    }
}
