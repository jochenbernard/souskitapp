import Synchronization

/// A clock that moves only when a test advances it, so what sleeps on it wakes at the same point however busy the
/// machine is.
final class TestClock: Clock, Sendable {
    /// A point on the clock.
    struct Instant: InstantProtocol {
        /// The time since the clock started.
        let offset: Duration

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }

        func advanced(by duration: Duration) -> Self {
            Self(offset: offset + duration)
        }

        func duration(to other: Self) -> Duration {
            other.offset - offset
        }
    }

    private struct Sleep {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var now = Instant(offset: .zero)
        var sleeps: [Int: Sleep] = [:]
        var nextSleep = 0
    }

    private let state = Mutex(State())

    var now: Instant {
        state.withLock({ $0.now })
    }

    var minimumResolution: Duration {
        .zero
    }

    func sleep(until deadline: Instant, tolerance _: Duration?) async throws {
        let id = state.withLock { state in
            state.nextSleep += 1

            return state.nextSleep
        }

        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    let isAwake = state.withLock { state in
                        guard deadline > state.now, !Task.isCancelled else {
                            return true
                        }

                        state.sleeps[id] = Sleep(deadline: deadline, continuation: continuation)

                        return false
                    }

                    if isAwake {
                        continuation.resume()
                    }
                }
            },
            onCancel: {
                state.withLock({ $0.sleeps.removeValue(forKey: id) })?.continuation.resume()
            }
        )

        try Task.checkCancellation()
    }

    /// Moves the clock on, waking whatever sleeps until then.
    ///
    /// - Parameter duration: How far to move it.
    func advance(by duration: Duration) {
        let awake = state.withLock { state in
            state.now = state.now.advanced(by: duration)
            let awake = state.sleeps.filter({ $0.value.deadline <= state.now })
            awake.keys.forEach({ state.sleeps[$0] = nil })

            return awake.values.map(\.continuation)
        }

        awake.forEach({ $0.resume() })
    }
}
