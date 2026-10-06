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
        /// How far open the timers were laid out.
        let openness: Double

        /// How far past where they open or fold to the timers were laid out.
        let rubberBand: CGFloat

        /// The fold that puts the timers there, with what is left of a pull past either end: negative past open and
        /// beyond ``RunningTimersLayoutMetrics/foldDistance`` past folded.
        ///
        /// A spring overshooting either end is left out, since it settles back on its own.
        let fold: CGFloat
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

    /// How far open the timers were laid out, as an animation in flight has them at that moment.
    var presentedOpenness: Double {
        values.withLock({ $0.presentedOpenness })
    }

    /// Where each timer was laid out, the soonest first, in the panel's content.
    var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] {
        values.withLock({ $0.timerFrames })
    }

    init() {}

    /// Where the timers were laid out, every value from the same layout pass.
    ///
    /// - Parameter dimension: How long the scroll view is along the fold.
    /// - Returns: How far open and past either end the timers were laid out, and the fold that puts them there.
    func presentedPosition(dimension: CGFloat) -> Position {
        values.withLock { values in
            let rubberBand = values.presentedRubberBand
            let pull = RubberBand.pull(forOffset: abs(rubberBand), dimension: dimension)

            return Position(
                openness: values.presentedOpenness,
                rubberBand: rubberBand,
                fold: (1.0 - values.presentedOpenness) * values.foldDistance + (rubberBand < 0.0 ? -pull : pull)
            )
        }
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
