@testable import FileRecipeLibrary
import Synchronization

/// Counts the listings of a directory, making a change right after the first listing that holds a given directory.
final class ListingSpy: Sendable {
    private struct State {
        var count = 0
        var hasChanged = false
    }

    private let change: @Sendable () throws -> Void
    private let directoryPath: String?
    private let state = Mutex(State())

    /// Creates a spy.
    ///
    /// - Parameters:
    ///   - directoryPath: The directory whose first listing the change follows, or `nil` for no change.
    ///   - change: The change.
    init(
        changingAfterListing directoryPath: String? = nil,
        change: @escaping @Sendable () throws -> Void = {}
    ) {
        self.directoryPath = directoryPath
        self.change = change
    }

    /// How many times the directory was listed.
    var count: Int {
        state.withLock({ $0.count })
    }

    /// Lists the directory and counts the listing.
    ///
    /// - Parameter reader: What the directory is listed with.
    /// - Returns: What the directory holds, as it was before the change.
    /// - Throws: Whatever listing or the change throws.
    func list(with reader: RecipeDirectoryReader) throws -> RecipeDirectoryListing {
        let listing = try reader.readListing()
        let changes = state.withLock { state in
            state.count += 1

            guard
                let directoryPath,
                !state.hasChanged,
                listing.directoryPaths.contains(directoryPath)
            else {
                return false
            }

            state.hasChanged = true

            return true
        }

        if changes {
            try change()
        }

        return listing
    }
}
