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

    /// When the timer started.
    var startDate: Date {
        endDate.addingTimeInterval(-stepTimer.seconds)
    }

    /// How much of the timer's time has run out by a date, from 0 when it starts to 1 once it is over.
    func fractionElapsed(at date: Date) -> Double {
        guard !isRinging else {
            return 1.0
        }

        guard stepTimer.seconds > 0.0 else {
            return 1.0
        }

        let secondsLeft = endDate.timeIntervalSince(date)
        return min(1.0, max(0.0, 1.0 - secondsLeft / stepTimer.seconds))
    }
}
