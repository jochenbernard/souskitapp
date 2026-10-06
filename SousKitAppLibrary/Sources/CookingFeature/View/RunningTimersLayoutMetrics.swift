import SwiftUI
import Synchronization

/// What ``RunningTimersLayout`` found as it last laid the timers out, and where each timer was last drawn swiped, for
/// the swipes that fold them and take them away to read.
///
/// Not observed: the layout writes it in every pass and the timers as they are drawn, and a swipe reads it as it
/// begins. Safe to use from any thread, since SwiftUI may lay the timers out away from the main thread while they
/// animate.
final class RunningTimersLayoutMetrics: Sendable {
    /// Where the timers lie: how far open, pulled past where they open or fold to, and held past the list's top.
    struct Position: Equatable {
        /// Open at the list's top, with nothing past it.
        static let open = Self(
            openness: 1.0,
            rubberBand: 0.0,
            heldBounce: 0.0
        )

        /// Folded into the stack, with nothing past it.
        static let folded = Self(
            openness: 0.0,
            rubberBand: 0.0,
            heldBounce: 0.0
        )

        /// How far open the timers are, past either end while a spring overshoots it.
        var openness: Double

        /// How far past where they open or fold to the timers are pulled.
        var rubberBand: CGFloat

        /// How far past its top the list is held where a finger caught it bouncing.
        var heldBounce: CGFloat

        /// The same position with nothing past open: open at most, pulled past folded only, held below the top only.
        var notPastOpen: Self {
            Self(
                openness: min(openness, 1.0),
                rubberBand: max(rubberBand, 0.0),
                heldBounce: max(heldBounce, 0.0)
            )
        }
    }

    /// What a layout pass found.
    struct Pass {
        /// How far the soonest timer travels from the list to the stack.
        var foldDistance: CGFloat = 1.0

        /// Where the timers were laid out.
        var presentedPosition = Position.folded

        /// Each timer and its frame in the panel's content, the soonest first.
        var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] = []

        /// The collapse button's frame in the panel's content, if there is one.
        var collapseButtonFrame: CGRect?
    }

    private let values = Mutex(Pass())

    // Apart from the pass, which each layout pass replaces whole.
    private let presentedSwipeOffsets = Mutex([RunningTimer.ID: CGFloat]())

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

    /// How far a timer was drawn swiped sideways, as an animation in flight has it.
    ///
    /// - Parameter id: The timer.
    /// - Returns: How far it was drawn swiped, left for negative values.
    func presentedSwipeOffset(of id: RunningTimer.ID) -> CGFloat {
        presentedSwipeOffsets.withLock({ $0[id] ?? 0.0 })
    }

    /// Records how far a timer was drawn swiped sideways.
    ///
    /// - Parameters:
    ///   - offset: How far it was drawn swiped, left for negative values.
    ///   - id: The timer.
    func updateSwipeOffset(_ offset: CGFloat, of id: RunningTimer.ID) {
        presentedSwipeOffsets.withLock({ $0[id] = offset })
    }

    /// Records what a layout pass found.
    ///
    /// - Parameter pass: What the pass found.
    func update(_ pass: Pass) {
        values.withLock({ $0 = pass })
    }
}
