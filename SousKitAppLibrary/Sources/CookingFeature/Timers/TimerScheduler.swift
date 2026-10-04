/// Timers that count down and go off when they are over, whether the app is open or not.
public protocol TimerScheduler: Sendable {
    /// The timers running, yielded once now and again after every change to them.
    ///
    /// Cancelling the task iterating the stream ends it.
    ///
    /// - Returns: The stream.
    @MainActor
    func runningTimers() -> AsyncStream<[RunningTimer]>

    /// Starts a timer counting down.
    ///
    /// - Parameter timer: The step's timer to start.
    /// - Throws: ``TimerSchedulerError/notAuthorized`` when the cook has not allowed timers, or whatever starting
    ///   the timer throws.
    @MainActor
    func start(_ timer: StepTimer) async throws

    /// Cancels a timer counting down, or silences one ringing.
    ///
    /// - Parameter timer: The timer to cancel.
    /// - Throws: Whatever cancelling the timer throws.
    @MainActor
    func cancel(_ timer: RunningTimer) throws
}
