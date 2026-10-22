import Foundation
import Synchronization

/// One coordinated access to a file, which another task can give up on while it waits.
final class CancellableFileCoordination: Sendable {
    private let coordinator = Mutex(NSFileCoordinator())

    /// Reads the item at a URL once it is on the device and whatever is writing to it has landed, holding no thread
    /// while it waits.
    ///
    /// Cancelling the task waiting gives up on the read.
    ///
    /// - Parameters:
    ///   - url: The item to read.
    ///   - queue: Where `read` runs.
    ///   - read: Reads the item at the URL it is handed, which may differ from `url`.
    /// - Returns: What `read` returns.
    /// - Throws: Whatever coordinating or `read` throws, or `CancellationError` when the task is cancelled first.
    static func read<T: Sendable>(
        at url: URL,
        queue: OperationQueue,
        _ read: @escaping @Sendable (URL) throws -> T
    ) async throws -> T {
        try Task.checkCancellation()

        let coordination = CancellableFileCoordination()

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    coordination.coordinateReading(at: url, queue: queue) { result in
                        continuation.resume(with: result.flatMap({ coordinatedURL in
                            Result(catching: { try read(coordinatedURL) })
                        }))
                    }
                }
            },
            onCancel: coordination.cancel
        )
    }

    private func coordinateReading(
        at url: URL,
        queue: OperationQueue,
        _ accessor: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        let intent = NSFileAccessIntent.readingIntent(with: url)

        coordinator.withLock { coordinator in
            coordinator.coordinate(with: [intent], queue: queue) { error in
                if let error {
                    accessor(.failure(error))
                } else {
                    accessor(.success(intent.url))
                }
            }
        }
    }

    // `NSFileCoordinator` allows cancelling from any thread.
    private func cancel() {
        coordinator.withLock({ $0.cancel() })
    }
}
