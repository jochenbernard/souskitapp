/// Why a ``TimerScheduler`` could not start a timer.
public enum TimerSchedulerError: Error {
    /// The cook has not allowed the app to run timers.
    case notAuthorized
}
