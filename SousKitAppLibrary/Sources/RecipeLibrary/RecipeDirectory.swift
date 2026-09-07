import Foundation

/// The directory holding the user's Sous files.
public struct RecipeDirectory: Sendable, Hashable {
    /// Where the directory sits on disk.
    public let url: URL

    /// The directory's own name, without the path leading up to it.
    public var name: String {
        url.lastPathComponent
    }

    /// The path to the directory, spelled out without percent escapes or a trailing separator.
    public var path: String {
        let spelledOut = url.path(percentEncoded: false)

        guard spelledOut.count > 1, spelledOut.hasSuffix("/") else {
            return spelledOut
        }

        return String(spelledOut.dropLast())
    }

    /// Creates a directory.
    ///
    /// - Parameter url: Where the directory sits on disk.
    public init(url: URL) {
        self.url = url
    }
}
