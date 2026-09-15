import Foundation

/// The recipes in a directory, read once and read again on every change to it.
@MainActor
public final class RecipeDirectoryMonitor {
    private let reader: RecipeDirectoryReader
    private let recipeDirectory: RecipeDirectory
    private let settleDelay: Duration

    private var continuation: AsyncStream<Result<[RecipeFile], Error>>.Continuation?
    private var eventSource: DirectoryEventSource?
    private var generation = 0
    private var hasYielded = false
    private var isScoped = false
    private var lastRecipeFiles: [RecipeFile] = []
    private var presenter: DirectoryPresenter?
    private var readTask: Task<Void, Never>?

    /// Creates a monitor.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory recipes are read from.
    ///   - settleDelay: How long a burst of changes is given to finish before the directory is
    ///     read again.
    nonisolated public init(
        recipeDirectory: RecipeDirectory,
        settleDelay: Duration = .milliseconds(150)
    ) {
        self.recipeDirectory = recipeDirectory
        self.settleDelay = settleDelay
        self.reader = RecipeDirectoryReader(recipeDirectory: recipeDirectory)
    }

    /// Lets go of what outlives a released monitor: `NSFileCoordinator` retains a file presenter,
    /// so a presenter left registered never reaches its own `deinit`.
    deinit {
        presenter?.stopPresenting()

        if isScoped {
            recipeDirectory.url.stopAccessingSecurityScopedResource()
        }
    }

    /// The recipes in the directory, yielded once now and again after every change to it.
    ///
    /// Watching starts here and stops when the stream ends, which cancelling the task iterating
    /// it does. The stream holds no reference back, so a caller that releases the monitor stops
    /// receiving. One stream runs at a time; a second call ends the first.
    ///
    /// - Returns: The stream.
    public func recipeFiles() -> AsyncStream<Result<[RecipeFile], Error>> {
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
    public func refresh() {
        guard continuation != nil else {
            return
        }

        read(afterSettling: false)
    }

    private func start() {
        let url = recipeDirectory.url
        isScoped = url.startAccessingSecurityScopedResource()

        let onChange: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in
                self?.read(afterSettling: true)
            }
        }

        // iCloud writes through file coordination and other apps on the device do not, so both are watched.
        presenter = DirectoryPresenter(directoryURL: url, onChange: onChange)
        eventSource = DirectoryEventSource(directoryURL: url, onChange: onChange)

        read(afterSettling: false)
    }

    private func stop() {
        readTask?.cancel()
        readTask = nil
        eventSource = nil
        presenter?.stopPresenting()
        presenter = nil
        hasYielded = false
        lastRecipeFiles = []
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
        readTask?.cancel()

        let delay = afterSettling ? settleDelay : .zero
        let directoryReader = reader

        readTask = Task { [weak self] in
            try? await Task.sleep(for: delay)

            guard !Task.isCancelled else {
                return
            }

            let result = await Self.readRecipeFiles(with: directoryReader)

            guard !Task.isCancelled else {
                return
            }

            self?.yield(result)
        }
    }

    /// Reads off the main actor, where a directory in iCloud can take a while to answer.
    @concurrent
    nonisolated private static func readRecipeFiles(
        with reader: RecipeDirectoryReader
    ) async -> Result<[RecipeFile], Error> {
        Result(catching: { try reader.readRecipeFiles() })
    }

    /// Sends a result on, dropping a list matching the one sent last.
    private func yield(_ result: Result<[RecipeFile], Error>) {
        switch result {
        case .success(let recipeFiles):
            guard !hasYielded || recipeFiles != lastRecipeFiles else {
                return
            }

            hasYielded = true
            lastRecipeFiles = recipeFiles

        case .failure:
            hasYielded = false
            lastRecipeFiles = []
        }

        continuation?.yield(result)
    }
}
