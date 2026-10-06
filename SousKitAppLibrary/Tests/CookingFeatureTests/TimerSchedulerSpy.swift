@testable import CookingFeature

/// Records the timers the cooking feature starts and cancels, and yields the running timers it is given.
@MainActor
final class TimerSchedulerSpy: TimerScheduler {
    private(set) var startedTimers: [StepTimer] = []
    private(set) var cancelledTimers: [RunningTimer] = []
    private let runningTimerUpdates: [[RunningTimer]]
    private let startError: Error?

    init(
        runningTimerUpdates: [[RunningTimer]] = [],
        startError: Error? = nil
    ) {
        self.runningTimerUpdates = runningTimerUpdates
        self.startError = startError
    }

    func currentRunningTimers() -> [RunningTimer] {
        runningTimerUpdates.first ?? []
    }

    func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream { continuation in
            for runningTimers in runningTimerUpdates {
                continuation.yield(runningTimers)
            }
            continuation.finish()
        }
    }

    func start(_ timer: StepTimer) throws {
        if let startError {
            throw startError
        }

        startedTimers.append(timer)
    }

    func cancel(_ timer: RunningTimer) {
        cancelledTimers.append(timer)
    }
}
