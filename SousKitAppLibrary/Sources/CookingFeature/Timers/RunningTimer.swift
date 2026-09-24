import Foundation

/// A timer counting down, or ringing once it is over.
public struct RunningTimer: Identifiable, Hashable, Sendable {
    /// Identifies the timer.
    public let id: UUID

    /// The step's timer this one was started from.
    public let stepTimer: StepTimer

    /// When the timer is over.
    public let endDate: Date

    /// Whether the timer is over and sounding its alarm.
    public let isRinging: Bool

    /// Creates a running timer.
    ///
    /// - Parameters:
    ///   - id: Identifies the timer.
    ///   - stepTimer: The step's timer this one was started from.
    ///   - endDate: When the timer is over.
    ///   - isRinging: Whether the timer is over and sounding its alarm.
    public init(
        id: UUID,
        stepTimer: StepTimer,
        endDate: Date,
        isRinging: Bool
    ) {
        self.id = id
        self.stepTimer = stepTimer
        self.endDate = endDate
        self.isRinging = isRinging
    }

    /// When the timer started.
    var startDate: Date {
        endDate.addingTimeInterval(-(stepTimer.duration / .seconds(1)))
    }

    /// How much of the timer's time has run out by a date, from 0 when it starts to 1 once it is over.
    func fractionElapsed(at date: Date) -> Double {
        guard !isRinging else {
            return 1.0
        }

        let seconds = stepTimer.duration / .seconds(1)
        guard seconds > 0.0 else {
            return 1.0
        }

        let secondsLeft = endDate.timeIntervalSince(date)
        return min(1.0, max(0.0, 1.0 - secondsLeft / seconds))
    }
}
