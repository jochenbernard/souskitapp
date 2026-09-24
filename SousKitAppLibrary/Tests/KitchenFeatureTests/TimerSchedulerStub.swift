import CookingFeature

/// A timer scheduler with no timers running, which starts none.
struct TimerSchedulerStub: TimerScheduler {
    func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream(unfolding: { nil })
    }

    func start(_: StepTimer) {}

    func cancel(_: RunningTimer) {}
}
