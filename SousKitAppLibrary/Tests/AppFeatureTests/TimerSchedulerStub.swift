import CookingFeature

/// A timer scheduler whose running timers change only when all of them are cancelled, which starts none.
@MainActor
final class TimerSchedulerStub: TimerScheduler {
    private(set) var timers: [RunningTimer]

    init(timers: [RunningTimer] = []) {
        self.timers = timers
    }

    func currentRunningTimers() -> [RunningTimer] {
        timers
    }

    func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream { continuation in
            continuation.yield(timers)
            continuation.finish()
        }
    }

    func start(_: CookingTimer) {}

    func cancel(_: RunningTimer) {}

    func cancelAll() {
        timers = []
    }
}
