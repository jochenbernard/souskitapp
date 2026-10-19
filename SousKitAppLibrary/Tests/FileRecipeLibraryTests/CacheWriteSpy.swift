import Foundation
import Synchronization

/// Counts the writes of a cache file, writing each.
final class CacheWriteSpy: Sendable {
    // How many times the file was written, after each write.
    private let counts: AsyncStream<Int>
    private let continuation: AsyncStream<Int>.Continuation
    private let writes = Mutex(0)

    init() {
        (self.counts, self.continuation) = AsyncStream.makeStream()
    }

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
        try data.write(to: url, options: .atomic)

        let written = writes.withLock { writes in
            writes += 1

            return writes
        }

        continuation.yield(written)
    }

    /// Returns once the file was written `count` times.
    ///
    /// - Parameter count: The number of writes to wait for.
    func waitForWrites(_ count: Int) async {
        guard self.count < count else {
            return
        }

        for await written in counts where written >= count {
            return
        }
    }
}
