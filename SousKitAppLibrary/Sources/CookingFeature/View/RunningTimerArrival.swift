import Observation
import SwiftUI

/// A timer that joins the folded stack behind the front one, on its way to its place: shown in front for a moment so
/// its start is seen, then swooping to its place behind the others.
@Observable
@MainActor
final class RunningTimerArrival {
    // How long the timer shows in front before it swoops to its place, and how long the swoop takes.
    private static let inFrontDuration = Duration.seconds(1.2)
    private static let swoopDuration = Duration.seconds(Animation.runningTimerSwoopDuration)

    // How often a timer waiting to swoop checks whether it is still being swiped or asked about, and how long it then
    // gives itself to settle back.
    private static let interactionPoll = Duration.milliseconds(100)
    private static let settleDuration = Duration.seconds(Animation.runningTimersDuration)

    /// The timer on its way, if any.
    private(set) var id: RunningTimer.ID?

    // How far it is on its swoop, from 0 shown in front to 1 in its place, or `nil` while it is shown in front.
    private var swoop: Double?

    nonisolated init() {}

    /// The timers as the stack shows them: soonest first, but for a timer shown in front for a moment.
    ///
    /// - Parameter timers: The running timers, soonest first.
    /// - Returns: The timers in the order they lie.
    func shown(_ timers: [RunningTimer]) -> [RunningTimer] {
        var shown = timers

        guard swoop == nil, let index = shown.firstIndex(where: { $0.id == id }) else {
            return shown
        }

        shown.insert(shown.remove(at: index), at: 0)
        return shown
    }

    /// How far a timer is on its swoop to its place.
    ///
    /// - Parameter timerID: The timer.
    /// - Returns: From 0 in front to 1 in its place, or `nil` for a timer not swooping.
    func swoop(of timerID: RunningTimer.ID) -> Double? {
        timerID == id ? swoop : nil
    }

    /// The timer on its way once it swoops to its place, rather than showing in front.
    var swoopingTimer: RunningTimer.ID? {
        swoop == nil ? nil : id
    }

    /// How far the timer on its way is on its swoop, which is where the stack lays it out.
    var swoopProgress: Double {
        swoop ?? 0.0
    }

    /// Brings a timer that joins behind the front one in front instead. The timers on screen as the view appears
    /// arrive all at once, so only timers joining others count.
    ///
    /// - Parameters:
    ///   - oldTimers: The running timers before.
    ///   - newTimers: The running timers now, soonest first.
    func timersDidChange(
        from oldTimers: [RunningTimer],
        to newTimers: [RunningTimer]
    ) {
        guard !oldTimers.isEmpty else {
            return
        }

        let joining = newTimers.enumerated().last { depth, timer in
            depth > 0 && !oldTimers.contains(where: { $0.id == timer.id })
        }

        if let joining {
            withAnimation(.runningTimers) {
                id = joining.element.id
                swoop = nil
            }
        }
    }

    /// Lets the timer on its way go to its place at once, as the open list shows every timer in its place.
    func settle() {
        id = nil
        swoop = nil
    }

    /// Takes the timer on its way to its place once it has shown in front for a moment, and never from under a
    /// finger or a question: it waits while it is swiped or its cancel is asked about, and for it to settle back
    /// after. Cut short by another arrival.
    ///
    /// - Parameters:
    ///   - isInteracting: Whether a timer is being swiped or its cancel asked about.
    ///   - isRunning: Whether a timer still runs, rather than having been taken away while in front.
    func takeToItsPlace(
        isInteracting: (RunningTimer.ID) -> Bool,
        isRunning: (RunningTimer.ID) -> Bool
    ) async {
        guard
            let id,
            await pause(for: Self.inFrontDuration),
            await waitWhile(isInteracting, with: id)
        else {
            return
        }

        guard isRunning(id) else {
            settle()
            return
        }

        // From 0, where the swoop starts in front, the same as where the timer is shown.
        withAnimation(.runningTimerSwoop) {
            swoop = 1.0
        }

        guard await pause(for: Self.swoopDuration) else {
            return
        }

        withAnimation(.runningTimers) {
            settle()
        }
    }

    // Whether the wait ran its course.
    private func waitWhile(_ isInteracting: (RunningTimer.ID) -> Bool, with id: RunningTimer.ID) async -> Bool {
        while isInteracting(id) {
            while isInteracting(id) {
                guard await pause(for: Self.interactionPoll) else {
                    return false
                }
            }

            guard await pause(for: Self.settleDuration) else {
                return false
            }
        }

        return true
    }

    // Whether the pause ran its course, rather than another arrival or the list opening cutting it short.
    private func pause(for duration: Duration) async -> Bool {
        (try? await Task.sleep(for: duration)) != nil
    }
}
