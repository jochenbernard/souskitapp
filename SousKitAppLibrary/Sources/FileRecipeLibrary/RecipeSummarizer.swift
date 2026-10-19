import Foundation
import RecipeLibrary
import SousKit

/// The summaries of a directory's recipes, read only where the cache holds none for a file's current contents.
actor RecipeSummarizer {
    /// A summary the cache holds, decoded once.
    private struct Summary {
        let record: RecipeSummaryRecord
        let summary: RecipeSummary
    }

    /// What reading a file returns: its text, and when the contents read last changed.
    private struct Contents {
        let text: String
        let modificationDate: Date?
    }

    private let cache: RecipeSummaryCache
    private let parser: SousParser
    private let queue: OperationQueue
    private let recipeDirectory: RecipeDirectory
    private let startDownloading: @Sendable (URL) throws -> Void

    private var isLoaded = false
    private var summaries: [String: Summary] = [:]

    /// Creates a summarizer.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory the recipes sit in.
    ///   - cache: Where the summaries are kept between launches.
    ///   - parser: What the recipes are read with.
    ///   - startDownloading: Asks iCloud for a file's contents, returning before they arrive.
    init(
        recipeDirectory: RecipeDirectory,
        cache: RecipeSummaryCache,
        parser: SousParser,
        startDownloading: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
    ) {
        let readQueue = OperationQueue()
        readQueue.maxConcurrentOperationCount = 1
        readQueue.qualityOfService = .utility

        self.recipeDirectory = recipeDirectory
        self.cache = cache
        self.parser = parser
        self.queue = readQueue
        self.startDownloading = startDownloading
    }

    /// The entries for files as they are listed now, each with the summary the cache holds for it, if any.
    ///
    /// A summary read from contents that have changed since stands in until they are read again. Summaries of files
    /// no longer listed are dropped.
    ///
    /// - Parameter files: The files the directory lists.
    /// - Returns: The entries, in the order of `files`.
    func recipeEntries(for files: [RecipeFile]) -> [RecipeEntry] {
        loadIfNeeded()

        let paths = Set(files.map(\.path))
        let removedPaths = summaries.keys.filter({ !paths.contains($0) })

        if !removedPaths.isEmpty {
            removedPaths.forEach({ summaries[$0] = nil })
            save()
        }

        return files.map({ $0.recipeEntry(summary: summaries[$0.path]?.summary) })
    }

    /// The files whose summary has to be read: those the cache holds none for, or one read from older contents.
    ///
    /// - Parameter files: The files the directory lists.
    /// - Returns: The files to read, in the order of `files`.
    func filesToRead(in files: [RecipeFile]) -> [RecipeFile] {
        loadIfNeeded()

        return files.filter { file in
            guard let summary = summaries[file.path] else {
                return true
            }

            return !summary.record.isCurrent(for: file)
        }
    }

    /// Reads files and keeps their summaries, fetching from iCloud the ones not on the device.
    ///
    /// A file that cannot be read keeps the summary it had. Cancelling the task stops at the file being read.
    ///
    /// - Parameter files: The files to read.
    func read(_ files: [RecipeFile]) async {
        loadIfNeeded()

        var hasRead = false

        for file in files {
            guard let contents = await contents(of: file) else {
                continue
            }

            let recipe = parser.parseRecipe(contents.text).value

            // Contents with no date could never be matched again, so they are summarized each time they are listed.
            guard let modificationDate = contents.modificationDate else {
                continue
            }

            let record = RecipeSummaryRecord(recipe: recipe, modificationDate: modificationDate)
            summaries[file.path] = Summary(record: record, summary: RecipeSummary(recipe: recipe))
            hasRead = true
        }

        if hasRead {
            save()
        }
    }

    private func contents(of file: RecipeFile) async -> Contents? {
        let directoryURL = recipeDirectory.url
        let url = directoryURL.appending(path: file.path)
        let isScoped = directoryURL.startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                directoryURL.stopAccessingSecurityScopedResource()
            }
        }

        if file.availability != .downloaded {
            // The coordinated read waits for the fetch, and reports one that cannot start.
            try? startDownloading(url)
        }

        return try? await CancellableFileCoordination.read(at: url, queue: queue) { coordinatedURL in
            Contents(
                text: try String(contentsOf: coordinatedURL, encoding: .utf8),
                modificationDate: try? coordinatedURL.resourceValues(
                    forKeys: [.contentModificationDateKey]
                ).contentModificationDate
            )
        }
    }

    private func loadIfNeeded() {
        guard !isLoaded else {
            return
        }

        isLoaded = true
        summaries = cache.load().mapValues { record in
            Summary(record: record, summary: record.summary(parsedWith: parser))
        }
    }

    private func save() {
        cache.save(summaries.mapValues(\.record))
    }
}
