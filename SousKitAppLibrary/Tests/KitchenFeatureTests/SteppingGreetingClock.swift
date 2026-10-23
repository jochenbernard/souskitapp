import Foundation
@testable import KitchenFeature
import Synchronization

/// A greeting clock whose sleeps end at once, with the time moved on to where they were to end, until it has woken
/// the given number of times. The sleep after that throws, as a cancelled one does.
final class SteppingGreetingClock: Sendable {
    private struct State {
        var now: Date
        var wakes: Int
        var sleeps: [Date] = []
    }

    private let calendar: Calendar

    private let state: Mutex<State>

    init(
        at date: Date,
        in calendar: Calendar,
        wakes: Int = 0
    ) {
        self.calendar = calendar
        self.state = Mutex(State(now: date, wakes: wakes))
    }

    /// Every moment a sleep was to end at, in turn.
    var sleeps: [Date] {
        state.withLock({ $0.sleeps })
    }

    /// The clock, to build a presenter with.
    var clock: KitchenGreetingClock {
        KitchenGreetingClock(
            now: { self.state.withLock({ $0.now }) },
            calendar: calendar,
            sleep: { date in try self.sleep(until: date) }
        )
    }

    /// Moves the time on, as the clock does while the app is away.
    func move(to date: Date) {
        state.withLock({ $0.now = date })
    }

    private func sleep(until date: Date) throws {
        try state.withLock { state in
            state.sleeps.append(date)

            guard state.wakes > 0 else {
                throw CancellationError()
            }

            state.wakes -= 1
            state.now = date
        }
    }
}
