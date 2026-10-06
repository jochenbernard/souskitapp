import SwiftUI
import Synchronization

/// What ``RunningTimersLayout`` found as it last laid the timers out, for the swipes that fold them and take them away
/// to read.
///
/// Not observed: the layout writes it in every pass, and a swipe reads it as it begins. Safe to use from any thread,
/// since SwiftUI may lay the timers out away from the main thread while they animate.
final class RunningTimersLayoutMetrics: Sendable {
    private struct Values {
        var foldDistance: CGFloat = 1.0
        var presentedOpenness = 0.0
        var presentedHeldBounce: CGFloat = 0.0
        var presentedFold: CGFloat = 0.0
        var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] = []
        var collapseButtonFrame: CGRect?
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

    /// How far past its top the list was laid out held where a finger caught it bouncing, as an animation in flight has
    /// it.
    var presentedHeldBounce: CGFloat {
        values.withLock({ $0.presentedHeldBounce })
    }

    /// How far a finger folds the timers to where they were laid out, as an animation in flight has them, down from the
    /// list for positive values.
    var presentedFold: CGFloat {
        values.withLock({ $0.presentedFold })
    }

    /// Where each timer was laid out, the soonest first, in the panel's content.
    var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] {
        values.withLock({ $0.timerFrames })
    }

    /// Where the button that folds the list back was laid out, in the panel's content, if anywhere.
    var collapseButtonFrame: CGRect? {
        values.withLock({ $0.collapseButtonFrame })
    }

    init() {}

    /// How far the soonest timer travels to the stack from the list held past its top.
    ///
    /// - Parameter held: How far past its top the list is held.
    /// - Returns: The distance, a point at least.
    func foldDistance(holding held: CGFloat) -> CGFloat {
        max(1.0, foldDistance - held)
    }

    /// Records what a layout pass found.
    ///
    /// - Parameters:
    ///   - foldDistance: How far the soonest timer travels from the list to the stack.
    ///   - presentedOpenness: How far open the timers were laid out.
    ///   - presentedHeldBounce: How far past its top the list was laid out held.
    ///   - presentedFold: How far a finger folds the timers to where they were laid out.
    ///   - timerFrames: Each timer and its frame in the panel's content, the soonest first.
    ///   - collapseButtonFrame: The collapse button's frame in the panel's content, if there is one.
    func update(
        foldDistance: CGFloat,
        presentedOpenness: Double,
        presentedHeldBounce: CGFloat,
        presentedFold: CGFloat,
        timerFrames: [(id: RunningTimer.ID, frame: CGRect)],
        collapseButtonFrame: CGRect?
    ) {
        values.withLock { values in
            values.foldDistance = foldDistance
            values.presentedOpenness = presentedOpenness
            values.presentedHeldBounce = presentedHeldBounce
            values.presentedFold = presentedFold
            values.timerFrames = timerFrames
            values.collapseButtonFrame = collapseButtonFrame
        }
    }
}
