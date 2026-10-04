import CookingFeature

/// A timer scheduler whose running timers never change, which starts none.
struct TimerSchedulerStub: TimerScheduler {
    var timers: [RunningTimer] = []

    func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream { continuation in
            continuation.yield(timers)
            continuation.finish()
        }
    }

    func start(_: StepTimer) {}

    func cancel(_: RunningTimer) {}
}
