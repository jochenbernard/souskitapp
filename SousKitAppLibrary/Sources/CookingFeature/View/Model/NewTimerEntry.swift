import Foundation

/// What the new timer sheet holds: a number as typed, and what that number counts.
struct NewTimerEntry: Equatable, Sendable {
    /// The longest a timer of an entered length runs, in seconds, which is a day.
    private static let longestSeconds = 86_400.0

    /// What the field holds, which is not a number until it is typed out.
    var text = ""

    /// What the number counts.
    var unit = TimerUnit.minutes

    /// How long the timer runs, to the second, or `nil` where the field holds no length from a second to a day.
    var duration: Duration? {
        guard let value else {
            return nil
        }

        let seconds = (value * unit.seconds).rounded()

        guard (1.0...Self.longestSeconds).contains(seconds) else {
            return nil
        }

        return .seconds(seconds)
    }

    /// The number the field holds, or `nil` where it holds none.
    ///
    /// A comma reads as a decimal point, since a decimal keypad offers whichever the region writes.
    private var value: Double? {
        let number = Double(
            text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )

        guard let number, number.isFinite else {
            return nil
        }

        return number
    }

    /// The entry a step from this one lands on: the next whole number, between one and a day of the unit.
    ///
    /// - Parameter steps: How many steps to take, which is -1 for the minus and 1 for the plus.
    /// - Returns: The entry stepped to.
    func stepped(by steps: Double) -> Self {
        let held = value ?? 0.0
        let whole = steps < 0.0 ? held.rounded(.up) : held.rounded(.down)
        let stepped = (whole + steps).clamped(to: 1.0...(Self.longestSeconds / unit.seconds))

        // A number outside the range stays put, rather than a step away from the range pulling it back into it.
        guard (stepped - held).sign == steps.sign else {
            return self
        }

        return Self(text: String(Int(stepped)), unit: unit)
    }
}
