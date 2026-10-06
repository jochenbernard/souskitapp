import SwiftUI

/// Where a finger's fold lays the running timers out once it catches them: how far open, and how far pulled past
/// either end.
///
/// Within the timers' two ends the finger moves them as far as it goes; past either, less and less the further. A
/// spring the finger catches can leave the timers part of the way open and pulled past at once, or past an end, so an
/// end starts where the finger caught them and moves on to where they open or fold as the finger pushes them there.
struct RunningTimersHold {
    /// The fold that holds the timers where the finger caught them: how far folded, with the pull past either end that
    /// puts them as far past it.
    let fold: CGFloat

    private let distance: CGFloat
    private let dimension: CGFloat

    // Where the timers open to: the list for a finger that can open it, and the stack for one that cannot.
    private let open: CGFloat

    // The ends the finger pulls the timers past while they are not where the timers open and fold, with how far it
    // caught them pulled past them.
    private var openEnd: (at: CGFloat, pull: CGFloat)?
    private var foldedEnd: (at: CGFloat, pull: CGFloat)?

    /// - Parameters:
    ///   - position: Where the timers are laid out as the finger catches them.
    ///   - distance: How far the soonest timer travels from the list to the stack.
    ///   - dimension: How long the scroll view is along the fold.
    ///   - canOpen: Whether the finger can open the list, or only pull the stack past where it folds.
    init(
        catching position: RunningTimersLayoutMetrics.Position,
        distance: CGFloat,
        dimension: CGFloat,
        canOpen: Bool
    ) {
        let caught = canOpen ? (1.0 - position.openness) * distance : distance
        let pull = RubberBand.pull(forOffset: abs(position.rubberBand), dimension: dimension)
        self.fold = caught + (position.rubberBand < 0.0 ? -pull : pull)
        self.distance = distance
        self.dimension = dimension
        self.open = canOpen ? 0.0 : distance

        if position.rubberBand < 0.0 {
            self.openEnd = (at: caught, pull: pull)
        } else if caught < self.open {
            self.openEnd = (at: caught, pull: 0.0)
        }

        if position.rubberBand > 0.0 {
            self.foldedEnd = (at: caught, pull: pull)
        } else if caught > distance {
            self.foldedEnd = (at: caught, pull: 0.0)
        }
    }

    /// Where the timers lie for a fold, the ends moved on as far as the finger has pushed them.
    ///
    /// - Parameter amount: How far the finger has the timers folded, from 0 open to the soonest timer's travel folded,
    ///   with any pull past either end: negative past open and beyond the travel past folded.
    /// - Returns: How far open and past either end the timers are laid out.
    mutating func position(at amount: CGFloat) -> RunningTimersLayoutMetrics.Position {
        let opened = moveOpenEnd(to: amount)
        let folded = max(opened, moveFoldedEnd(to: amount))

        let rubberBand = if amount < opened {
            -RubberBand.offset(forPull: opened - amount, dimension: dimension)
        } else if amount > folded {
            RubberBand.offset(forPull: amount - folded, dimension: dimension)
        } else {
            0.0
        }

        return RunningTimersLayoutMetrics.Position(
            openness: 1.0 - amount.clamped(to: opened...folded) / distance,
            rubberBand: rubberBand
        )
    }

    // An end goes back to where the timers open or fold once the finger has them on the near side of both, and moves
    // out toward there as the finger pulls them on past it.
    private mutating func moveOpenEnd(to amount: CGFloat) -> CGFloat {
        guard let end = openEnd, amount < max(end.at, open) else {
            openEnd = nil
            return open
        }

        let moved = min(end.at, max(open, amount + end.pull))
        openEnd = (at: moved, pull: end.pull)
        return moved
    }

    private mutating func moveFoldedEnd(to amount: CGFloat) -> CGFloat {
        guard let end = foldedEnd, amount > min(end.at, distance) else {
            foldedEnd = nil
            return distance
        }

        let moved = max(end.at, min(distance, amount - end.pull))
        foldedEnd = (at: moved, pull: end.pull)
        return moved
    }
}
