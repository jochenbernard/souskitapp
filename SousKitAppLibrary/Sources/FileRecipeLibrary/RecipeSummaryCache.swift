import Foundation
import Synchronization

/// The summaries of one directory's recipes, kept between launches in a file the system may clear.
struct RecipeSummaryCache: Sendable {
    private struct Contents: Codable {
        let directoryPath: String
        let records: [String: RecipeSummaryRecord]
    }

    // By file: the directory whose cache was made last, the only one still writing it.
    private static let writers = Mutex<[URL: String]>([:])

    private let directoryPath: String
    private let fileURL: URL
    private let write: @Sendable (Data, URL) throws -> Void

    /// Creates a cache, which from then on is the only one writing the file, so work still running for another
    /// directory writes nothing.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory whose recipes are summarized.
    ///   - fileURL: Where the summaries are kept, which holds one directory's at a time.
    ///   - write: Writes the data to the file at the URL.
    init(
        recipeDirectory: RecipeDirectory,
        fileURL: URL,
        write: @escaping @Sendable (Data, URL) throws -> Void = { data, url in
            try data.write(to: url, options: .atomic)
        }
    ) {
        let path = recipeDirectory.url.standardizedFileURL.path(percentEncoded: false)
        Self.writers.withLock({ $0[fileURL] = path })

        self.directoryPath = path
        self.fileURL = fileURL
        self.write = write
    }

    /// The summaries kept, by the path of the recipe inside the directory.
    ///
    /// - Returns: The records, or none where the file is gone, unreadable, or kept for another directory.
    func load() -> [String: RecipeSummaryRecord] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let contents = try? JSONDecoder().decode(Contents.self, from: data),
            contents.directoryPath == directoryPath
        else {
            return [:]
        }

        return contents.records
    }

    /// Keeps summaries, replacing those kept before, unless a cache for another directory was made since.
    ///
    /// A cache that cannot be written is read again on the next launch, so a failure is dropped.
    ///
    /// - Parameter records: The records, by the path of the recipe inside the directory.
    func save(_ records: [String: RecipeSummaryRecord]) {
        let contents = Contents(directoryPath: directoryPath, records: records)

        guard let data = try? JSONEncoder().encode(contents) else {
            return
        }

        // Held while writing, so a cache made meanwhile never has its file written over by this one.
        Self.writers.withLock { writers in
            guard writers[fileURL] == directoryPath else {
                return
            }

            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? write(data, fileURL)
        }
    }
}
