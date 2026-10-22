@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary

/// A directory of its own under the temporary directory, removed when the suite holding it goes.
final class TemporaryDirectory: Sendable {
    /// Where the directory sits on disk.
    let url: URL

    /// Where the summaries of the directory's recipes are kept, beside the directory rather than in it.
    let summaryCacheURL: URL

    /// Creates a directory, named for the suite and a fresh UUID so suites never share one.
    ///
    /// - Parameter name: The suite's name.
    /// - Throws: Whatever creating the directory throws.
    init(named name: String) throws {
        let directoryURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "\(name).\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.url = directoryURL
        self.summaryCacheURL = directoryURL.appendingPathExtension("RecipeSummaries.json")
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: summaryCacheURL)
    }

    /// The directory, as the library takes it.
    var recipeDirectory: RecipeDirectory {
        RecipeDirectory(url: url)
    }

    /// Writes an empty file into the directory.
    ///
    /// - Parameter fileName: The name to write it under.
    /// - Throws: Whatever writing the file throws.
    func writeFile(named fileName: String) throws {
        try Data().write(to: url.appending(path: fileName))
    }

    /// Writes a file holding `text`.
    ///
    /// - Parameters:
    ///   - fileName: The name to write it under.
    ///   - text: What the file holds.
    /// - Returns: The recipe the file is read as.
    /// - Throws: Whatever writing the file throws.
    @discardableResult
    func writeFile(named fileName: String, _ text: String) throws -> RecipeEntry {
        try Data(text.utf8).write(to: url.appending(path: fileName))

        return RecipeEntry(fileName: fileName, availability: .downloaded)
    }

    /// The cache keeping the summaries of the directory's recipes.
    var summaryCache: RecipeSummaryCache {
        RecipeSummaryCache(recipeDirectory: recipeDirectory, fileURL: summaryCacheURL)
    }

    /// Sets when a file's contents last changed.
    ///
    /// - Parameters:
    ///   - date: The date.
    ///   - fileName: The file's name inside the directory.
    /// - Throws: Whatever changing the file's attributes throws.
    func setModificationDate(_ date: Date, ofFileNamed fileName: String) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: url.appending(path: fileName).path(percentEncoded: false)
        )
    }

    /// Creates a directory inside this one.
    ///
    /// - Parameter name: The name to create it under.
    /// - Throws: Whatever creating the directory throws.
    func makeDirectory(named name: String) throws {
        try FileManager.default.createDirectory(
            at: url.appending(path: name),
            withIntermediateDirectories: true
        )
    }
}
