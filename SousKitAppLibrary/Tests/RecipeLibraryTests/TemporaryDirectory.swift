import Foundation
import RecipeLibrary

/// A directory of its own under the temporary directory, removed when the suite holding it goes.
final class TemporaryDirectory: Sendable {
    /// Where the directory sits on disk.
    let url: URL

    /// Creates a directory, named for the suite and a fresh UUID so suites never share one.
    ///
    /// - Parameter name: The suite's name.
    /// - Throws: Whatever creating the directory throws.
    init(named name: String) throws {
        let directoryURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "\(name).\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.url = directoryURL
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
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
    func writeFile(named fileName: String, _ text: String) throws -> RecipeFile {
        let fileURL = url.appending(path: fileName)
        try Data(text.utf8).write(to: fileURL)

        return RecipeFile(url: fileURL, availability: .downloaded)
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
