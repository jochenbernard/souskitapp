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

    private let cache: RecipeSummaryCache
    private let parser: SousParser
    private let saveInterval: Duration
    private let textReader: RecipeTextReader

    private var lastSave: ContinuousClock.Instant?
    private var pendingSave: Task<Void, Never>?

    private lazy var summaries: [String: Summary] = cache.load().mapValues { record in
        Summary(record: record, summary: record.summary(parsedWith: parser))
    }

    /// Creates a summarizer.
    ///
    /// - Parameters:
    ///   - cache: Where the summaries are kept between launches.
    ///   - parser: What the recipes are read with.
    ///   - textReader: What the recipes' files are read with.
    ///   - saveInterval: The shortest time between two writes of the cache, so a burst of reads writes it once.
    init(
        cache: RecipeSummaryCache,
        parser: SousParser,
        textReader: RecipeTextReader,
        saveInterval: Duration = .seconds(1)
    ) {
        self.cache = cache
        self.parser = parser
        self.textReader = textReader
        self.saveInterval = saveInterval
    }

    /// The entries for files as they are listed now, each with the summary the cache holds for it, if any.
    ///
    /// A summary read from contents that have changed since stands in until they are read again. Summaries of files
    /// no longer listed are dropped.
    ///
    /// - Parameter files: The files the directory lists.
    /// - Returns: The entries, in the order of `files`.
    func recipeEntries(for files: [RecipeFile]) -> [RecipeEntry] {
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
        files.filter { file in
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
        var hasRead = false

        for file in files {
            guard
                let contents = try? await textReader.read(fileName: file.path, availability: file.availability)
            else {
                continue
            }

            let recipe = parser.parseRecipe(contents.text).value

            // Contents with no date could never be matched again, so they are summarized each time they are listed.
            guard let modificationDate = contents.modificationDate else {
                continue
            }

            let record = RecipeSummaryRecord(recipe: recipe, modificationDate: modificationDate)
            summaries[file.path] = Summary(record: record, summary: RecipeSummary(recipe: recipe, parser: parser))
            hasRead = true
        }

        if hasRead {
            save()
        }
    }

    /// Writes the summaries now, or once `saveInterval` has passed since the last write, taking along whatever is read
    /// meanwhile.
    private func save() {
        guard pendingSave == nil else {
            return
        }

        guard let lastSave, ContinuousClock.now < lastSave.advanced(by: saveInterval) else {
            write()
            return
        }

        let deadline = lastSave.advanced(by: saveInterval)

        // Holding the summarizer, so what was read is written even after the directory is let go.
        pendingSave = Task {
            try? await Task.sleep(until: deadline)
            write()
        }
    }

    private func write() {
        pendingSave = nil
        lastSave = .now
        cache.save(summaries.mapValues(\.record))
    }
}
