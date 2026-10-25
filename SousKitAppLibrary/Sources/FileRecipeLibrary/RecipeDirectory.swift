import Foundation

/// The directory holding the user's Sous files.
struct RecipeDirectory: Sendable, Hashable {
    /// Where the directory sits on disk.
    let url: URL

    /// The directory's own name, without the path leading up to it.
    var name: String {
        url.lastPathComponent
    }

    /// Where a file sits inside the directory, at any depth.
    ///
    /// - Parameter fileURL: The file.
    /// - Returns: The path, extension included, or `nil` where the file sits outside the directory.
    func path(ofFileAt fileURL: URL) -> String? {
        let directoryComponents = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let fileComponents = fileURL.standardizedFileURL.resolvingSymlinksInPath().pathComponents

        guard
            fileComponents.count > directoryComponents.count,
            fileComponents.starts(with: directoryComponents)
        else {
            return nil
        }

        return fileComponents.dropFirst(directoryComponents.count).joined(separator: "/")
    }
}
