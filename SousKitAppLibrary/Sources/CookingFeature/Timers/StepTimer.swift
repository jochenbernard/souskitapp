/// A timer a step names, with the length of time it runs.
public struct StepTimer: Hashable, Codable, Sendable {
    /// The number of the step naming the timer.
    public let stepNumber: Int

    /// The timer as written, such as `15 min`.
    public let text: String

    /// How long the timer runs.
    public let duration: Duration
}
