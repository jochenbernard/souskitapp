import Foundation

/// Reads a recipe's text, fetching it from iCloud where it is not on the device.
public struct RecipeTextReader: Sendable {
    private let recipeDirectory: RecipeDirectory

    /// Creates a reader.
    ///
    /// - Parameter recipeDirectory: The directory the recipes sit in.
    public init(recipeDirectory: RecipeDirectory) {
        self.recipeDirectory = recipeDirectory
    }

    /// Reads a recipe.
    ///
    /// A recipe held only in iCloud is fetched first, and the call returns once the text is on
    /// the device, so it takes as long as that fetch does.
    ///
    /// - Parameter recipeFile: The recipe to read.
    /// - Returns: The recipe's text.
    /// - Throws: Whatever fetching or reading the file throws.
    public func readText(of recipeFile: RecipeFile) throws -> String {
        try recipeDirectory.url.withSecurityScope {
            if recipeFile.availability != .downloaded {
                // The coordinated read reports a fetch that cannot start, and waits for one that can.
                try? FileManager.default.startDownloadingUbiquitousItem(at: recipeFile.url)
            }

            return try NSFileCoordinator.coordinateReading(at: recipeFile.url) { coordinatedURL in
                try String(contentsOf: coordinatedURL, encoding: .utf8)
            }
        }
    }
}
