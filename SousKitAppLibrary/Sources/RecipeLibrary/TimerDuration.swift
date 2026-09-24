import SousKit

/// How long a step's timers run, read from the units they are written in.
public enum TimerDuration {
    private static let secondsPerUnit: [String: Double] = [
        "s": 1, "sec": 1, "secs": 1, "second": 1, "seconds": 1, "seconde": 1, "seconden": 1,
        "min": 60, "mins": 60, "minute": 60, "minutes": 60, "minuut": 60, "minuten": 60,
        "h": 3_600, "hr": 3_600, "hrs": 3_600, "hour": 3_600, "hours": 3_600, "u": 3_600, "uur": 3_600, "uren": 3_600,
        "d": 86_400, "day": 86_400, "days": 86_400, "dag": 86_400, "dagen": 86_400
    ]

    /// How long a timer runs, or `nil` where it names no length of time, such as `overnight`.
    ///
    /// A range runs for its low end, so the cook checks before it can be over. A compound timer runs for the sum of
    /// its parts. English and Dutch units are read.
    ///
    /// - Parameter timer: The timer to read.
    /// - Returns: How long the timer runs.
    public static func duration(of timer: SousKit.Timer) -> Duration? {
        var seconds = 0.0

        for component in timer.components {
            guard let componentSeconds = self.seconds(of: component) else {
                return nil
            }

            seconds += componentSeconds
        }

        guard seconds > 0 else {
            return nil
        }

        return .seconds(seconds)
    }

    private static func seconds(of component: Amount) -> Double? {
        guard
            let unit = component.unit,
            let unitSeconds = secondsPerUnit[unitName(unit)]
        else {
            return nil
        }

        switch component.kind {
        case .precise(let quantity), .range(let quantity, _):
            return quantity.value * unitSeconds

        case .imprecise:
            return nil
        }
    }

    /// A unit as the table spells it, so `Min.` reads as `min`.
    private static func unitName(_ unit: String) -> String {
        let lowercased = unit.lowercased()
        return lowercased.hasSuffix(".") ? String(lowercased.dropLast()) : lowercased
    }
}
