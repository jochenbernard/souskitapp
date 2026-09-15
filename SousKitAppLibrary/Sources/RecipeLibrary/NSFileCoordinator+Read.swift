import Foundation

extension NSFileCoordinator {
    /// Reads the item at a URL once whatever iCloud or another app is writing to it has landed.
    static func coordinateReading<T>(at url: URL, _ read: (URL) throws -> T) throws -> T {
        var outcome = Result<T, Error>.failure(CocoaError(.fileReadUnknown))
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(
            readingItemAt: url,
            error: &coordinationError
        ) { coordinatedURL in
            outcome = Result(catching: { try read(coordinatedURL) })
        }

        if let coordinationError {
            throw coordinationError
        }

        return try outcome.get()
    }
}
