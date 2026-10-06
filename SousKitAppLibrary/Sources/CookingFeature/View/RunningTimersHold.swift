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

    private let canOpen: Bool
    private let dimension: CGFloat

    // The ends the finger pulls the timers past while they are not where the timers open and fold, and how far it
    // caught them pulled past them.
    private var openEnd: CGFloat?
    private var foldedEnd: CGFloat?
    private var pullUp: CGFloat = 0.0
    private var pullDown: CGFloat = 0.0

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
        let open = canOpen ? 0.0 : distance
        let caught = canOpen ? (1.0 - position.openness) * distance : distance
        let pull = RubberBand.pull(forOffset: abs(position.rubberBand), dimension: dimension)
        self.fold = caught + (position.rubberBand < 0.0 ? -pull : pull)
        self.canOpen = canOpen
        self.dimension = dimension

        if position.rubberBand < 0.0 {
            self.openEnd = caught
            self.pullUp = pull
        } else if caught < open {
            self.openEnd = caught
        }

        if position.rubberBand > 0.0 {
            self.foldedEnd = caught
            self.pullDown = pull
        } else if caught > distance {
            self.foldedEnd = caught
        }
    }

    /// Where the timers lie for a fold, the ends moved on as far as the finger has pushed them.
    ///
    /// - Parameters:
    ///   - amount: How far the finger has the timers folded, from 0 open to `distance` folded, with any pull past
    ///     either end: negative past open and beyond `distance` past folded.
    ///   - distance: How far the soonest timer travels from the list to the stack.
    /// - Returns: How far open and past either end the timers are laid out.
    mutating func position(at amount: CGFloat, distance: CGFloat) -> RunningTimersLayoutMetrics.Position {
        let opened = moveOpenEnd(to: amount, open: canOpen ? 0.0 : distance)
        let folded = max(opened, moveFoldedEnd(to: amount, distance: distance))

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
    private mutating func moveOpenEnd(to amount: CGFloat, open: CGFloat) -> CGFloat {
        guard let end = openEnd, amount < max(end, open) else {
            openEnd = nil
            pullUp = 0.0
            return open
        }

        let moved = min(end, max(open, amount + pullUp))
        openEnd = moved
        return moved
    }

    private mutating func moveFoldedEnd(to amount: CGFloat, distance: CGFloat) -> CGFloat {
        guard let end = foldedEnd, amount > min(end, distance) else {
            foldedEnd = nil
            pullDown = 0.0
            return distance
        }

        let moved = max(end, min(distance, amount - pullDown))
        foldedEnd = moved
        return moved
    }
}
