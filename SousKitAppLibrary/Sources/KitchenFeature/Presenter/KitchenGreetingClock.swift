import Foundation

/// The time the kitchen greets the cook by, and how it waits for the greeting to change.
struct KitchenGreetingClock: Sendable {
    /// The device's time, in the cook's own calendar and time zone.
    static let system = Self(
        now: { .now },
        calendar: .autoupdatingCurrent,
        sleep: { date in
            try await Task.sleep(for: .seconds(max(date.timeIntervalSinceNow, 0.0)))
        }
    )

    /// The current moment.
    let now: @Sendable () -> Date

    /// The calendar and time zone the cook reads the time in.
    let calendar: Calendar

    /// Waits until a moment, throwing when the task is cancelled first.
    let sleep: @Sendable (Date) async throws -> Void
}
