import Foundation
import Synchronization

/// Counts the writes of a cache file, writing each.
final class CacheWriteSpy: Sendable {
    private let writes = Mutex(0)

    /// How many times the file was written.
    var count: Int {
        writes.withLock({ $0 })
    }

    /// Writes the file and counts the write.
    ///
    /// - Parameters:
    ///   - data: What the file holds.
    ///   - url: Where the file sits.
    /// - Throws: Whatever writing throws.
    func write(_ data: Data, to url: URL) throws {
        writes.withLock({ $0 += 1 })
        try data.write(to: url, options: .atomic)
    }
}
