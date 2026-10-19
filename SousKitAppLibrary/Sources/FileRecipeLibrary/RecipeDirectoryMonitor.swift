import Foundation
import RecipeLibrary

/// The recipes in a directory and in the directories inside it, read once and read again on every change to them.
@MainActor
final class RecipeDirectoryMonitor {
    private let listDirectory: @Sendable () throws -> RecipeDirectoryListing
    private let present: @Sendable (URL, @escaping @Sendable () -> Void) -> DirectoryPresenter?
    private let recipeDirectory: RecipeDirectory
    private let settleDelay: Duration
    private let summarizer: RecipeSummarizer

    private var continuation: AsyncStream<Result<[ListedRecipe], Error>>.Continuation?
    // By path: an event source hears its own directory's entries alone, so each directory listed has one.
    private var eventSources: [String: DirectoryEventSource] = [:]
    // By path, and left running by a new read of the directory: a landing file changes the directory.
    private var fetches: [String: Task<Void, Never>] = [:]
    private var generation = 0
    private var isScoped = false
    // swiftlint:disable:next discouraged_optional_collection
    private var lastListedRecipes: [ListedRecipe]?
    private var presenter: DirectoryPresenter?
    private var readTask: Task<Void, Never>?
    private var recipeFiles: [RecipeFile] = []

    /// Creates a monitor.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory recipes are read from.
    ///   - summarizer: What the recipes' summaries come from.
    ///   - settleDelay: How long a burst of changes is given to finish before the directory is
    ///     read again.
    ///   - listDirectory: Lists the directory with the reader handed to it.
    ///   - present: Presents the directory at the URL, calling the closure on every change, or presents nothing.
    nonisolated init(
        recipeDirectory: RecipeDirectory,
        summarizer: RecipeSummarizer,
        settleDelay: Duration = .milliseconds(150),
        listDirectory: @escaping @Sendable (RecipeDirectoryReader) throws -> RecipeDirectoryListing = { reader in
            try reader.readListing()
        },
        present: @escaping @Sendable (URL, @escaping @Sendable () -> Void) -> DirectoryPresenter? = { url, onChange in
            DirectoryPresenter(directoryURL: url, onChange: onChange)
        }
    ) {
        let reader = RecipeDirectoryReader(recipeDirectory: recipeDirectory)
        self.recipeDirectory = recipeDirectory
        self.summarizer = summarizer
        self.settleDelay = settleDelay
        self.listDirectory = { try listDirectory(reader) }
        self.present = present
    }

    /// Lets go of what outlives a released monitor: `NSFileCoordinator` retains a file presenter,
    /// so a presenter left registered never reaches its own `deinit`.
    deinit {
        readTask?.cancel()
        fetches.values.forEach({ $0.cancel() })
        continuation?.finish()
        presenter?.stopPresenting()

        if isScoped {
            recipeDirectory.url.stopAccessingSecurityScopedResource()
        }
    }

    /// The recipes in the directory, yielded once now and again after every change to it.
    ///
    /// Each read yields the recipes with the summaries already cached first, then again as the summaries of new or
    /// changed files are read, so a launch lists them before reading any file. Watching starts here and stops when
    /// the stream ends, which cancelling the task iterating it or releasing the monitor does. The stream holds no
    /// reference back. One stream runs at a time; a second call ends the first.
    ///
    /// - Returns: The stream.
    func listedRecipes() -> AsyncStream<Result<[ListedRecipe], Error>> {
        stop()
        generation += 1
        let startedAt = generation

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { streamContinuation in
            continuation = streamContinuation
            streamContinuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.stop(startedAt: startedAt)
                }
            }
            start()
        }
    }

    /// Reads the directory again, for the changes that reach the app no other way: a sync that
    /// landed while the app was in the background.
    func refresh() {
        read(afterSettling: false)
    }

    private func start() {
        let url = recipeDirectory.url
        isScoped = url.startAccessingSecurityScopedResource()

        // iCloud writes through file coordination, heard at any depth, and other apps do not, so both are watched.
        presenter = present(url, makeOnChange())
        watch(directoriesAt: [""])

        read(afterSettling: false)
    }

    private func makeOnChange() -> @Sendable () -> Void {
        { [weak self] in
            Task { @MainActor in
                self?.read(afterSettling: true)
            }
        }
    }

    /// Watches the directories listed for the changes that reach them without file coordination, and stops watching
    /// those no longer listed.
    ///
    /// - Parameter directoryPaths: Where the directories sit inside the recipe directory, empty for itself.
    /// - Returns: Whether a directory is watched that was not before.
    @discardableResult
    private func watch(directoriesAt directoryPaths: Set<String>) -> Bool {
        eventSources = eventSources.filter({ directoryPaths.contains($0.key) })
        var watchesNewDirectory = false

        for path in directoryPaths where eventSources[path] == nil {
            let url = path.isEmpty ? recipeDirectory.url : recipeDirectory.url.appending(path: path)
            eventSources[path] = DirectoryEventSource(directoryURL: url, onChange: makeOnChange())
            watchesNewDirectory = watchesNewDirectory || eventSources[path] != nil
        }

        return watchesNewDirectory
    }

    private func stop() {
        readTask?.cancel()
        readTask = nil
        fetches.values.forEach({ $0.cancel() })
        fetches = [:]
        recipeFiles = []
        eventSources = [:]
        presenter?.stopPresenting()
        presenter = nil
        lastListedRecipes = nil
        continuation?.finish()
        continuation = nil

        if isScoped {
            recipeDirectory.url.stopAccessingSecurityScopedResource()
            isScoped = false
        }
    }

    /// Stops, unless a later stream has taken over since.
    private func stop(startedAt generation: Int) {
        guard generation == self.generation else {
            return
        }

        stop()
    }

    /// Reads the directory and yields the result.
    ///
    /// - Parameter afterSettling: Whether to let a burst of changes finish first.
    private func read(afterSettling: Bool) {
        // A change already on its way when the stream stopped would otherwise read for no one.
        guard continuation != nil else {
            return
        }

        readTask?.cancel()

        let delay = afterSettling ? settleDelay : .zero

        readTask = Task { [weak self, listDirectory, summarizer] in
            try? await Task.sleep(for: delay)

            guard !Task.isCancelled else {
                return
            }

            var result = await Self.readListing(with: listDirectory)

            // A change to a directory between its listing and its watch goes unheard, so a new watch lists again.
            while
                !Task.isCancelled,
                case .success(let listing) = result,
                self?.didList(listing) == true
            {
                result = await Self.readListing(with: listDirectory)
            }

            guard !Task.isCancelled else {
                return
            }

            switch result {
            case .success(let listing):
                await Self.readSummaries(
                    of: listing.recipeFiles,
                    with: summarizer,
                    yield: { [weak self] listedRecipes in self?.yield(.success(listedRecipes)) },
                    fetch: { [weak self] filesToRead in self?.fetch(filesToRead) ?? [] }
                )

            case .failure(let error):
                self?.yield(.failure(error))
            }
        }
    }

    /// Reads off the main actor, where a directory in iCloud can take a while to answer.
    @concurrent
    nonisolated private static func readListing(
        with listDirectory: @Sendable () throws -> RecipeDirectoryListing
    ) async -> Result<RecipeDirectoryListing, Error> {
        Result(catching: listDirectory)
    }

    /// Yields the recipes with the summaries the cache holds, then reads those it has none for, yielding the recipes
    /// again as they land.
    ///
    /// The files on the device are read together. Holding no monitor, it leaves a released one free to go.
    ///
    /// - Parameter fetch: Fetches the files in iCloud among those handed to it, returning the files on the device
    ///   that no fetch reads.
    private static func readSummaries(
        of recipeFiles: [RecipeFile],
        with summarizer: RecipeSummarizer,
        yield: @escaping @MainActor ([ListedRecipe]) -> Void,
        fetch: @MainActor ([RecipeFile]) -> [RecipeFile]
    ) async {
        let yieldSummaries = {
            let listedRecipes = await summarizer.listedRecipes(for: recipeFiles)

            if !Task.isCancelled {
                yield(listedRecipes)
            }
        }

        await yieldSummaries()

        let filesToRead = await summarizer.filesToRead(in: recipeFiles)

        guard !Task.isCancelled else {
            return
        }

        let filesOnDevice = fetch(filesToRead)

        if !filesOnDevice.isEmpty {
            await summarizer.read(filesOnDevice)
            await yieldSummaries()
        }
    }

    /// Keeps a listing, watching the directories it holds and giving up on the fetches of files it no longer holds.
    ///
    /// - Returns: Whether a directory is watched that was not before.
    private func didList(_ listing: RecipeDirectoryListing) -> Bool {
        recipeFiles = listing.recipeFiles
        let watchesNewDirectory = watch(directoriesAt: listing.directoryPaths)

        let paths = Set(recipeFiles.map(\.path))

        for (path, fetch) in fetches where !paths.contains(path) {
            fetch.cancel()
            fetches[path] = nil
        }

        return watchesNewDirectory
    }

    /// Fetches each file in iCloud on its own, so one that never arrives holds up no other, leaving alone those
    /// already on their way.
    ///
    /// - Parameter filesToRead: The files whose summaries have to be read.
    /// - Returns: The files on the device among them, but for those a fetch is reading.
    private func fetch(_ filesToRead: [RecipeFile]) -> [RecipeFile] {
        let filesToFetch = filesToRead.filter({ $0.availability != .downloaded && fetches[$0.path] == nil })

        for file in filesToFetch {
            fetches[file.path] = Task { [weak self, summarizer] in
                await summarizer.read([file])

                guard !Task.isCancelled else {
                    return
                }

                self?.fetches[file.path] = nil

                guard let listedFiles = self?.recipeFiles else {
                    return
                }

                let listedRecipes = await summarizer.listedRecipes(for: listedFiles)

                if !Task.isCancelled {
                    self?.yield(.success(listedRecipes))
                }
            }
        }

        return filesToRead.filter({ $0.availability == .downloaded && fetches[$0.path] == nil })
    }

    /// Sends a result on, dropping a list matching the one sent last.
    private func yield(_ result: Result<[ListedRecipe], Error>) {
        switch result {
        case .success(let listedRecipes):
            guard listedRecipes != lastListedRecipes else {
                return
            }

            lastListedRecipes = listedRecipes

        case .failure:
            lastListedRecipes = nil
        }

        continuation?.yield(result)
    }
}
