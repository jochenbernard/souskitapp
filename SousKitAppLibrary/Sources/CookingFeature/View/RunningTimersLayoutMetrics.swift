import SwiftUI
import Synchronization

/// What ``RunningTimersLayout`` found as it last laid the timers out, for the swipes that fold them and take them away
/// to read.
///
/// Not observed: the layout writes it in every pass, and a swipe reads it as it begins. Safe to use from any thread,
/// since SwiftUI may lay the timers out away from the main thread while they animate.
final class RunningTimersLayoutMetrics: Sendable {
    /// What a layout pass found.
    struct Pass {
        /// How far the soonest timer travels from the list to the stack.
        var foldDistance: CGFloat = 1.0

        /// How far open the timers were laid out.
        var presentedOpenness = 0.0

        /// How far past its top the list was laid out held.
        var presentedHeldBounce: CGFloat = 0.0

        /// How far a finger folds the timers to where they were laid out.
        var presentedFold: CGFloat = 0.0

        /// Each timer and its frame in the panel's content, the soonest first.
        var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] = []

        /// The collapse button's frame in the panel's content, if there is one.
        var collapseButtonFrame: CGRect?
    }

    private let values = Mutex(Pass())

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
    /// - Parameter pass: What the pass found.
    func update(_ pass: Pass) {
        values.withLock({ $0 = pass })
    }
}
