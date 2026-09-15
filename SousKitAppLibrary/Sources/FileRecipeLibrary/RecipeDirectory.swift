import Foundation

/// The directory holding the user's Sous files.
struct RecipeDirectory: Sendable, Hashable {
    /// Where the directory sits on disk.
    let url: URL

    /// The directory's own name, without the path leading up to it.
    var name: String {
        url.lastPathComponent
    }
}
