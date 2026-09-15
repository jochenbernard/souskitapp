import Foundation

/// The directory holding the user's Sous files.
public struct RecipeDirectory: Sendable, Hashable {
    /// Where the directory sits on disk.
    public let url: URL

    /// The directory's own name, without the path leading up to it.
    public var name: String {
        url.lastPathComponent
    }

    /// Creates a directory.
    ///
    /// - Parameter url: Where the directory sits on disk.
    public init(url: URL) {
        self.url = url
    }
}
