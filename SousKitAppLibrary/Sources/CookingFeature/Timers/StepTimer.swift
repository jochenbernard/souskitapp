import RecipeLibrary
import SousKit

/// A timer a step names, with the length of time it runs.
public struct StepTimer: Hashable, Codable, Sendable {
    /// The number of the step naming the timer.
    public let stepNumber: Int

    /// The timer as written, such as `15 min`.
    public let text: String

    /// How long the timer runs.
    public let duration: Duration

    init(
        stepNumber: Int,
        text: String,
        duration: Duration
    ) {
        self.stepNumber = stepNumber
        self.text = text
        self.duration = duration
    }

    /// A step's timer, or `nil` where it names no length of time.
    init?(_ timer: SousKit.Timer, stepNumber: Int) {
        guard let timerDuration = TimerDuration.duration(of: timer) else {
            return nil
        }

        self.init(
            stepNumber: stepNumber,
            text: timer.text,
            duration: timerDuration
        )
    }
}
