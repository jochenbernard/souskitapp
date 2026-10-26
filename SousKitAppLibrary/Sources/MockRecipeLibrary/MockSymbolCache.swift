import Foundation
import RecipeLibrary

/// The symbols picked for the mock recipes, kept between launches in a file the system may clear.
struct MockSymbolCache: Sendable {
    private let fileURL: URL

    /// Creates a cache.
    ///
    /// - Parameter fileURL: Where the picks are kept.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The picks kept, by recipe id.
    ///
    /// - Returns: The picks, or none where the file is gone or unreadable.
    func load() -> [String: RecipeSymbolPick] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let picks = try? JSONDecoder().decode([String: RecipeSymbolPick].self, from: data)
        else {
            return [:]
        }

        return picks
    }

    /// Keeps a pick in place of the one kept before for its recipe.
    ///
    /// A cache that cannot be written leaves the next launch to pick again, so a failure is dropped.
    ///
    /// - Parameters:
    ///   - pick: The pick.
    ///   - id: The recipe's id.
    func keep(_ pick: RecipeSymbolPick, forRecipeWithID id: String) {
        var picks = load()
        picks[id] = pick

        guard let data = try? JSONEncoder().encode(picks) else {
            return
        }

        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Removes every pick kept.
    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
