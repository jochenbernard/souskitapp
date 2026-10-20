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

    /// A clock read as the time since the summarizer was made, so no instant of its type is kept.
    private struct Timeline: Sendable {
        let now: @Sendable () -> Duration
        let sleep: @Sendable (Duration) async throws -> Void

        init<C: Clock<Duration>>(clock: C) {
            let start = clock.now

            self.now = { start.duration(to: clock.now) }
            self.sleep = { try await clock.sleep(until: start.advanced(by: $0), tolerance: nil) }
        }
    }

    private let cache: RecipeSummaryCache
    private let parser: SousParser
    private let saveInterval: Duration
    private let textReader: RecipeTextReader
    private let timeline: Timeline

    private var lastSave: Duration?
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
    ///   - clock: What `saveInterval` is measured on.
    init<C: Clock<Duration>>(
        cache: RecipeSummaryCache,
        parser: SousParser,
        textReader: RecipeTextReader,
        saveInterval: Duration = .seconds(1),
        clock: C = ContinuousClock()
    ) {
        self.cache = cache
        self.parser = parser
        self.textReader = textReader
        self.saveInterval = saveInterval
        self.timeline = Timeline(clock: clock)
    }

    /// The recipes for files as they are listed now, each with the summary and ingredient names the cache holds for
    /// it, if any.
    ///
    /// A summary read from contents that have changed since stands in until they are read again. Summaries of files
    /// no longer listed are dropped.
    ///
    /// - Parameters:
    ///   - files: The files the directory lists.
    ///   - pictures: The pictures the directory lists, by where each sits inside it.
    /// - Returns: The recipes, in the order of `files`.
    func listedRecipes(for files: [RecipeFile], pictures: [String: RecipePicture]) -> [ListedRecipe] {
        let paths = Set(files.map(\.path))
        let removedPaths = summaries.keys.filter({ !paths.contains($0) })

        if !removedPaths.isEmpty {
            removedPaths.forEach({ summaries[$0] = nil })
            save()
        }

        return files.map { file in
            let summary = summaries[file.path]

            return ListedRecipe(
                entry: file.recipeEntry(summary: summary?.summary, pictures: pictures),
                ingredientNames: summary?.record.ingredientNames ?? [],
                symbolPick: summary?.record.symbolPick
            )
        }
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
                let contents = try? await textReader.read(path: file.path, availability: file.availability)
            else {
                continue
            }

            let recipe = parser.parseRecipe(contents.text).value

            // Contents with no date could never be matched again, so they are summarized each time they are listed.
            guard let modificationDate = contents.modificationDate else {
                continue
            }

            // The pick stays until the queue finds it was made from something the recipe no longer says.
            let record = RecipeSummaryRecord(
                recipe: recipe,
                modificationDate: modificationDate,
                symbolPick: summaries[file.path]?.record.symbolPick
            )
            summaries[file.path] = Summary(record: record, summary: RecipeSummary(recipe: recipe, parser: parser))
            hasRead = true
        }

        if hasRead {
            save()
        }
    }

    /// Keeps the symbol picked for a recipe with its summary, unless the recipe has no summary any more.
    ///
    /// - Parameters:
    ///   - symbolPick: The pick.
    ///   - path: Where the recipe's file sits inside the directory.
    func keep(_ symbolPick: RecipeSymbolPick, forRecipeAt path: String) {
        guard let summary = summaries[path] else {
            return
        }

        var record = summary.record
        record.symbolPick = symbolPick
        summaries[path] = Summary(record: record, summary: summary.summary)
        save()
    }

    /// Writes the summaries now, or once `saveInterval` has passed since the last write, taking along whatever is read
    /// meanwhile.
    private func save() {
        guard pendingSave == nil else {
            return
        }

        guard let lastSave, timeline.now() < lastSave + saveInterval else {
            write()
            return
        }

        let deadline = lastSave + saveInterval

        // Holding the summarizer, so what was read is written even after the directory is let go.
        pendingSave = Task {
            try? await timeline.sleep(deadline)
            write()
        }
    }

    private func write() {
        pendingSave = nil
        lastSave = timeline.now()
        cache.save(summaries.mapValues(\.record))
    }
}
