import Foundation
import RecipeLibrary

/// The recipes in a directory and in the directories inside it, read once and read again on every change to them, with
/// the pictures they name fetched from iCloud and the thumbnails of those they no longer name removed.
@MainActor
final class RecipeDirectoryMonitor {
    private let listDirectory: @Sendable () throws -> RecipeDirectoryListing
    private let pictureFetcher: RecipePictureFetcher
    private let present: @Sendable (URL, @escaping @Sendable () -> Void) -> DirectoryPresenter?
    private let recipeDirectory: RecipeDirectory
    private let settleDelay: Duration
    private let summarizer: RecipeSummarizer
    private let thumbnailCache: RecipeThumbnailCache?

    private var continuation: AsyncStream<Result<[ListedRecipe], Error>>.Continuation?
    // By path: an event source hears its own directory's entries alone, so each directory listed has one.
    private var eventSources: [String: DirectoryEventSource] = [:]
    // By path, and left running by a new read of the directory: a landing file changes the directory.
    private var fetches: [String: Task<Void, Never>] = [:]
    private var generation = 0
    private var isScoped = false
    // The pictures whose thumbnails were kept when the cache was last cleared of the others.
    // swiftlint:disable:next discouraged_optional_collection
    private var keptThumbnailPictures: Set<RecipePicture>?
    // swiftlint:disable:next discouraged_optional_collection
    private var lastListedRecipes: [ListedRecipe]?
    private var pictures: [String: RecipePicture] = [:]
    private var presenter: DirectoryPresenter?
    // swiftlint:disable:next discouraged_optional_collection
    private var readAheadTask: Task<[ListedRecipe]?, Never>?
    private var readTask: Task<Void, Never>?
    private var recipeFiles: [RecipeFile] = []

    /// Creates a monitor.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory recipes are read from.
    ///   - summarizer: What the recipes' summaries come from.
    ///   - thumbnailCache: Where the thumbnails of the recipes' pictures are kept, or `nil` where none are.
    ///   - settleDelay: How long a burst of changes is given to finish before the directory is
    ///     read again.
    ///   - fileStatus: What the file system reports of the file at a URL, or of the file iCloud promises there.
    ///   - listDirectory: Lists the directory with the reader handed to it.
    ///   - present: Presents the directory at the URL, calling the closure on every change, or presents nothing.
    ///   - startDownloadingPicture: Asks iCloud for a picture's contents, returning before they arrive.
    nonisolated init(
        recipeDirectory: RecipeDirectory,
        summarizer: RecipeSummarizer,
        thumbnailCache: RecipeThumbnailCache? = nil,
        settleDelay: Duration = .milliseconds(150),
        fileStatus: @escaping @Sendable (URL) -> RecipeFileStatus? = RecipeFileStatus.read(at:),
        listDirectory: @escaping @Sendable (RecipeDirectoryReader) throws -> RecipeDirectoryListing = { reader in
            try reader.readListing()
        },
        present: @escaping @Sendable (URL, @escaping @Sendable () -> Void) -> DirectoryPresenter? = { url, onChange in
            DirectoryPresenter(directoryURL: url, onChange: onChange)
        },
        startDownloadingPicture: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    ) {
        let reader = RecipeDirectoryReader(recipeDirectory: recipeDirectory, fileStatus: fileStatus)
        self.pictureFetcher = RecipePictureFetcher(
            reader: RecipePictureReader(
                recipeDirectory: recipeDirectory,
                qualityOfService: .utility,
                fileStatus: fileStatus,
                startDownloading: startDownloadingPicture
            )
        )
        self.recipeDirectory = recipeDirectory
        self.summarizer = summarizer
        self.thumbnailCache = thumbnailCache
        self.settleDelay = settleDelay
        self.listDirectory = { try listDirectory(reader) }
        self.present = present
    }

    /// Lets go of what outlives a released monitor: `NSFileCoordinator` retains a file presenter,
    /// so a presenter left registered never reaches its own `deinit`.
    deinit {
        readAheadTask?.cancel()
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

    /// Lists the recipes with the summaries the cache holds, before any stream asks, for the next stream to yield
    /// before its own read.
    ///
    /// The stream still reads the directory itself, and yields again only what changed since.
    func readAhead() {
        readAheadTask?.cancel()
        // Detached, so the recipes are ready even while the main actor is busy putting the first screen up.
        readAheadTask = Task.detached(priority: .userInitiated) { [listDirectory, summarizer] in
            guard let listing = try? listDirectory() else {
                return nil
            }

            return await summarizer.listedRecipes(for: listing.recipeFiles, pictures: listing.pictures)
        }
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
        pictureFetcher.stop()
        pictures = [:]
        recipeFiles = []
        eventSources = [:]
        presenter?.stopPresenting()
        presenter = nil
        lastListedRecipes = nil
        keptThumbnailPictures = nil
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
        let readAhead = readAheadTask
        readAheadTask = nil

        readTask = Task { [weak self, listDirectory, summarizer] in
            try? await Task.sleep(for: delay)

            guard !Task.isCancelled else {
                return
            }

            // Shown while the directory is listed again, now that it is watched.
            if let listedRecipes = await readAhead?.value, !Task.isCancelled {
                self?.yield(.success(listedRecipes))
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
                    of: listing,
                    with: summarizer,
                    yield: { [weak self] listedRecipes in self?.yield(.success(listedRecipes)) },
                    fetch: { [weak self] filesToRead in self?.fetch(filesToRead) ?? [] }
                )

            case .failure(let error):
                self?.yield(.failure(error))
            }
        }
    }

    /// Keeps a listing, watching the directories it holds and giving up on the fetches of files it no longer holds.
    ///
    /// - Returns: Whether a directory is watched that was not before.
    private func didList(_ listing: RecipeDirectoryListing) -> Bool {
        recipeFiles = listing.recipeFiles
        pictures = listing.pictures
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

                guard let listedFiles = self?.recipeFiles, let listedPictures = self?.pictures else {
                    return
                }

                let listedRecipes = await summarizer.listedRecipes(for: listedFiles, pictures: listedPictures)

                if !Task.isCancelled {
                    self?.yield(.success(listedRecipes))
                }
            }
        }

        return filesToRead.filter({ $0.availability == .downloaded && fetches[$0.path] == nil })
    }

    /// Sends a result on, dropping a list matching the one sent last, fetches the pictures its recipes name that are
    /// not on the device, and removes the thumbnails of those they do not name.
    private func yield(_ result: Result<[ListedRecipe], Error>) {
        switch result {
        case .success(let listedRecipes):
            guard listedRecipes != lastListedRecipes else {
                return
            }

            lastListedRecipes = listedRecipes
            // Read again rather than left to a change event, which a landing picture is not sure to send.
            pictureFetcher.fetchPictures(namedIn: listedRecipes) { [weak self] in
                self?.read(afterSettling: true)
            }
            removeThumbnails(unnamedIn: listedRecipes)

        case .failure:
            lastListedRecipes = nil
        }

        continuation?.yield(result)
    }

    /// Removes the thumbnails of the pictures the recipes do not name, once for each set of pictures they name.
    private func removeThumbnails(unnamedIn listedRecipes: [ListedRecipe]) {
        let namedPictures = Set(listedRecipes.compactMap(\.entry.picture))

        guard let thumbnailCache, namedPictures != keptThumbnailPictures else {
            return
        }

        keptThumbnailPictures = namedPictures

        Task {
            await thumbnailCache.removeThumbnails(keeping: namedPictures)
        }
    }
}
