import Foundation

/// The summaries of one directory's recipes, kept between launches in a file the system may clear.
struct RecipeSummaryCache: Sendable {
    private struct Contents: Codable {
        let directoryPath: String
        let records: [String: RecipeSummaryRecord]
    }

    private let directoryPath: String
    private let fileURL: URL

    /// Creates a cache.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory whose recipes are summarized.
    ///   - fileURL: Where the summaries are kept, which holds one directory's at a time.
    init(
        recipeDirectory: RecipeDirectory,
        fileURL: URL
    ) {
        self.directoryPath = recipeDirectory.url.standardizedFileURL.path(percentEncoded: false)
        self.fileURL = fileURL
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

    /// Keeps summaries, replacing those kept before.
    ///
    /// A cache that cannot be written is read again on the next launch, so a failure is dropped.
    ///
    /// - Parameter records: The records, by the path of the recipe inside the directory.
    func save(_ records: [String: RecipeSummaryRecord]) {
        let contents = Contents(directoryPath: directoryPath, records: records)

        guard let data = try? JSONEncoder().encode(contents) else {
            return
        }

        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }
}
