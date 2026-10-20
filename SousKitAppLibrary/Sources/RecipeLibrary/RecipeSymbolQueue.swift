/// Follows a repository's recipes and picks the symbols they are missing, one at a time in the background while symbols
/// can be picked, listing the recipes again with each pick as it lands.
///
/// A recipe is picked for where its contents have been read and it is listed with no pick made from what it says now,
/// those without a picture first. A pick the picker is too busy for is asked for again a few times, each after a longer
/// wait. A pick that fails otherwise is not asked for again until its input changes or picking becomes possible again
/// after it was not. Picks are kept as long as the queue is, and handed on to be kept longer.
@MainActor
public final class RecipeSymbolQueue {
    private typealias Listing = Result<[ListedRecipe], Error>

    private struct Request: Hashable {
        let id: String
        let input: RecipeSymbolInput
    }

    // How often a pick the picker was too busy for is asked for again before it counts as failed.
    private static let busyRetryLimit = 5

    private let busyRetryDelay: Duration
    private let picker: RecipeSymbolPicker
    private let save: (@MainActor (String, RecipeSymbolPick) async -> Void)?

    // How often picking stopped being possible, so a pick failing meanwhile is not taken for a lasting failure.
    private var availabilityLossCount = 0
    private var availabilityTask: Task<Void, Never>?
    private var busyRetries: [Request: Int] = [:]
    private var continuation: AsyncStream<Listing>.Continuation?
    private var failedRequests: Set<Request> = []
    private var generation = 0
    private var inputs = RecipeSymbolInputs()
    private var isAvailable = false
    private var pickTask: Task<Void, Never>?
    // By recipe id.
    private var picks: [String: RecipeSymbolPick] = [:]
    private var requests: [Request] = []
    // The recipes listed last, with their picks, or `nil` where no stream is followed or the last listing failed.
    // swiftlint:disable:next discouraged_optional_collection
    private var shownRecipes: [ListedRecipe]?

    /// Creates a queue, which picks nothing until it follows a stream.
    ///
    /// - Parameters:
    ///   - picker: What the symbols are picked with.
    ///   - busyRetryDelay: How long to wait before asking again for a pick the picker was too busy for, doubled each
    ///     time it is again.
    ///   - save: Keeps a pick beyond the queue, for the recipe with the id, before the next pick is asked for, or
    ///     `nil` where picks last as long as the queue.
    nonisolated public init(
        picker: RecipeSymbolPicker,
        busyRetryDelay: Duration = .seconds(2),
        save: (@MainActor (String, RecipeSymbolPick) async -> Void)? = nil
    ) {
        self.busyRetryDelay = busyRetryDelay
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
        if let listedRecipes = try? listing.get() {
            inputs.keep(listedRecipes)
        }

        let picked = listing.map(withPicks)
        streamContinuation.yield(picked)

        // A stream already replaced still sends on what it was sent, but no longer decides what is picked.
        guard generation == self.generation else {
            return
        }

        shownRecipes = try? picked.get()
        requests = requests(for: shownRecipes ?? [])
        forgetUnaskedFailures()
        watchAvailability()
        startPicking()
    }

    private func stopFollowing(at generation: Int) {
        guard generation == self.generation else {
            return
        }

        availabilityTask?.cancel()
        availabilityTask = nil
        continuation = nil
        isAvailable = false
        requests = []
        shownRecipes = nil
    }

    /// The recipes, each with the pick made here in place of the one it is listed with, where this one is current and
    /// that one not.
    private func withPicks(_ listedRecipes: [ListedRecipe]) -> [ListedRecipe] {
        guard !picks.isEmpty else {
            return listedRecipes
        }

        let promptVersion = picker.promptVersion

        return listedRecipes.map { listedRecipe in
            guard
                let pick = picks[listedRecipe.entry.id],
                let input = inputs.input(for: listedRecipe),
                listedRecipe.symbolPick?.isCurrent(for: input, promptVersion: promptVersion) != true,
                pick.isCurrent(for: input, promptVersion: promptVersion)
            else {
                return listedRecipe
            }

            var pickedRecipe = listedRecipe
            pickedRecipe.symbolPick = pick

            return pickedRecipe
        }
    }

    /// What has to be picked for the recipes: those listed with no current pick.
    private func requests(for listedRecipes: [ListedRecipe]) -> [Request] {
        let promptVersion = picker.promptVersion
        var withoutPicture: [Request] = []
        var withPicture: [Request] = []

        for listedRecipe in listedRecipes {
            guard
                let input = inputs.input(for: listedRecipe),
                listedRecipe.symbolPick?.isCurrent(for: input, promptVersion: promptVersion) != true
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

    /// Forgets the failures of what is no longer asked for, because its recipe went or changed.
    private func forgetUnaskedFailures() {
        guard !failedRequests.isEmpty || !busyRetries.isEmpty else {
            return
        }

        let asked = Set(requests)
        failedRequests.formIntersection(asked)
        busyRetries = busyRetries.filter({ asked.contains($0.key) })
    }

    private func watchAvailability() {
        guard availabilityTask == nil else {
            return
        }

        availabilityTask = Task { [weak self, picker] in
            for await canPick in picker.availabilityUpdates() {
                // An update already on its way when following stops is not taken in.
                guard !Task.isCancelled else {
                    return
                }

                self?.didChangeAvailability(canPick)
            }
        }
    }

    private func didChangeAvailability(_ isAvailable: Bool) {
        // What failed while picking was becoming impossible is asked for again once it is possible.
        if isAvailable, !self.isAvailable {
            busyRetries = [:]
            failedRequests = []
        } else if !isAvailable, self.isAvailable {
            availabilityLossCount += 1
        }

        self.isAvailable = isAvailable
        startPicking()
    }

    private func startPicking() {
        guard pickTask == nil, nextRequest != nil else {
            return
        }

        pickTask = Task { [weak self, picker] in
            while !Task.isCancelled, let request = self?.nextRequest, let lossCount = self?.availabilityLossCount {
                let outcome: Result<String, Error>

                do {
                    outcome = .success(try await picker.symbol(for: request.input))
                } catch {
                    outcome = .failure(error)
                }

                guard !Task.isCancelled else {
                    return
                }

                let delay = await self?.finish(
                    request,
                    with: outcome,
                    availabilityLossCount: lossCount
                )

                if let delay {
                    try? await Task.sleep(for: delay)
                }
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

    /// Takes in what a request came to, returning how long to wait before the next one where the picker was too busy.
    private func finish(
        _ request: Request,
        with outcome: Result<String, Error>,
        availabilityLossCount: Int
    ) async -> Duration? {
        switch outcome {
        case .success(let symbol):
            busyRetries[request] = nil
            requests.removeAll(where: { $0 == request })

            let pick = RecipeSymbolPick(
                symbol: symbol,
                input: request.input,
                promptVersion: picker.promptVersion
            )
            picks[request.id] = pick
            show(pick, forRecipeWithID: request.id)

            await save?(request.id, pick)
            return nil

        case .failure(let error) where error is RecipeSymbolPickerBusyError:
            let retries = busyRetries[request, default: 0]

            guard retries < Self.busyRetryLimit else {
                busyRetries[request] = nil
                failedRequests.insert(request)
                return nil
            }

            busyRetries[request] = retries + 1
            return busyRetryDelay * (1 << retries)

        case .failure:
            // A pick that failed while picking stopped being possible is asked for again once it is possible.
            if availabilityLossCount == self.availabilityLossCount {
                failedRequests.insert(request)
            }

            return nil
        }
    }

    /// Lists the recipes listed last again with a pick, where its recipe is still listed as it was when picked.
    private func show(_ pick: RecipeSymbolPick, forRecipeWithID id: String) {
        // Only the picked recipe changes, so the others are not checked again.
        guard
            var listedRecipes = shownRecipes,
            let index = listedRecipes.firstIndex(where: { $0.entry.id == id }),
            let input = inputs.input(for: listedRecipes[index]),
            pick.isCurrent(for: input, promptVersion: picker.promptVersion)
        else {
            return
        }

        listedRecipes[index].symbolPick = pick
        shownRecipes = listedRecipes
        continuation?.yield(.success(listedRecipes))
    }
}
