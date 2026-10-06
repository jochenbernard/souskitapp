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

        /// How far past its top the list was laid out held where a finger caught it bouncing.
        let heldBounce: CGFloat

        /// The same position with nothing past open: open at most, pulled past folded only, held below the top only.
        var notPastOpen: Self {
            Self(
                openness: min(openness, 1.0),
                rubberBand: max(rubberBand, 0.0),
                heldBounce: max(heldBounce, 0.0)
            )
        }

        /// The same position with the list held further past its top.
        ///
        /// - Parameter bounce: How much further past its top the list is held.
        /// - Returns: The position.
        func holding(further bounce: CGFloat) -> Self {
            Self(
                openness: openness,
                rubberBand: rubberBand,
                heldBounce: heldBounce + bounce
            )
        }
    }

    /// What a layout pass found.
    struct Pass {
        /// How far the soonest timer travels from the list to the stack.
        var foldDistance: CGFloat = 1.0

        /// Where the timers were laid out.
        var presentedPosition = Position(
            openness: 0.0,
            rubberBand: 0.0,
            heldBounce: 0.0
        )

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

    /// Where the timers were laid out, all of it from the same layout pass.
    var presentedPosition: Position {
        values.withLock({ $0.presentedPosition })
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

    /// Records what a layout pass found.
    ///
    /// - Parameter pass: What the pass found.
    func update(_ pass: Pass) {
        values.withLock({ $0 = pass })
    }
}
