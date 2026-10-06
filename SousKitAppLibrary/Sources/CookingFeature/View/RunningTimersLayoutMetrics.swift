import SwiftUI
import Synchronization

/// What ``RunningTimersLayout`` found as it last laid the timers out, for the swipes that fold them and take them away
/// to read.
///
/// Not observed: the layout writes it in every pass, and a swipe reads it as it begins. Safe to use from any thread,
/// since SwiftUI may lay the timers out away from the main thread while they animate.
final class RunningTimersLayoutMetrics: Sendable {
    /// Where the timers were laid out, as an animation in flight has them.
    struct Position {
        /// How far open the timers were laid out, past either end while a spring overshoots it.
        let openness: Double

        /// How far past where they open or fold to the timers were laid out.
        let rubberBand: CGFloat

        /// The same position with nothing past open: open at most, and pulled past folded only.
        var notPastOpen: Self {
            Self(openness: min(openness, 1.0), rubberBand: max(rubberBand, 0.0))
        }
    }

    private struct Values {
        var foldDistance: CGFloat = 1.0
        var presentedOpenness = 0.0
        var presentedRubberBand: CGFloat = 0.0
        var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] = []
    }

    private let values = Mutex(Values())

    /// How far the soonest timer travels from its place in the list to its place in the stack.
    var foldDistance: CGFloat {
        values.withLock({ $0.foldDistance })
    }

    /// Where each timer was laid out, the soonest first, in the panel's content.
    var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] {
        values.withLock({ $0.timerFrames })
    }

    init() {}

    /// Where the timers were laid out, both values from the same layout pass.
    var presentedPosition: Position {
        values.withLock({ Position(openness: $0.presentedOpenness, rubberBand: $0.presentedRubberBand) })
    }

    /// Records what a layout pass found.
    ///
    /// - Parameters:
    ///   - foldDistance: How far the soonest timer travels from the list to the stack.
    ///   - presentedOpenness: How far open the timers were laid out.
    ///   - presentedRubberBand: How far past where they open or fold to the timers were laid out.
    ///   - timerFrames: Each timer and its frame in the panel's content, the soonest first.
    func update(
        foldDistance: CGFloat,
        presentedOpenness: Double,
        presentedRubberBand: CGFloat,
        timerFrames: [(id: RunningTimer.ID, frame: CGRect)]
    ) {
        values.withLock { values in
            values.foldDistance = foldDistance
            values.presentedOpenness = presentedOpenness
            values.presentedRubberBand = presentedRubberBand
            values.timerFrames = timerFrames
        }
    }
}
