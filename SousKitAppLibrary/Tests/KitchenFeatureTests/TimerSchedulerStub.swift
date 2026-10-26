import CookingFeature

/// A timer scheduler whose running timers never change, which starts none.
struct TimerSchedulerStub: TimerScheduler {
    var timers: [RunningTimer] = []

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

    func cancelAll() {}
}
