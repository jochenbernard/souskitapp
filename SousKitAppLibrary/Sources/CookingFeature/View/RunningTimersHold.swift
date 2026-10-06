import SwiftUI

/// Where a finger's fold lays the running timers out once it catches them: how far open, how far past its top the list
/// is held, and how far pulled past either end.
///
/// Within the timers' two ends the finger moves them as far as it goes; past either, less and less the further. A
/// spring the finger catches can leave the timers part of the way open and pulled past at once, or past an end, so an
/// end starts where the finger caught them and moves on to where they open or fold as the finger pushes them there.
/// A list caught past its top folds from there, and short of open the finger takes that bounce up before it pulls the
/// timers past, moving every timer alike as the bounce did.
struct RunningTimersHold {
    /// The fold that holds the timers where the finger caught them: the bounce held, how far folded from there, and
    /// the pull past either end that puts them as far past it.
    let fold: CGFloat

    /// How far the soonest timer travels to the stack from the list held where the finger caught it.
    let distance: CGFloat

    private let bounce: CGFloat
    private let dimension: CGFloat

    // Where the timers open to: the list for a finger that can open it, and the stack for one that cannot.
    private let open: CGFloat

    // The ends the timers were caught away from where they open and fold, with how far past them they were pulled.
    private var openEnd: (at: CGFloat, pull: CGFloat)?
    private var foldedEnd: (at: CGFloat, pull: CGFloat)?

    /// - Parameters:
    ///   - position: Where the timers are laid out as the finger catches them.
    ///   - distance: How far the soonest timer travels from the list at its top to the stack.
    ///   - dimension: How long the scroll view is along the fold.
    ///   - canOpen: Whether the finger can open the list, or only pull the stack past where it folds.
    init(
        catching position: RunningTimersLayoutMetrics.Position,
        distance: CGFloat,
        dimension: CGFloat,
        canOpen: Bool
    ) {
        let travel = max(1.0, distance - position.heldBounce)
        let caught = canOpen ? (1.0 - position.openness) * travel : travel
        let pull = RubberBand.pull(forOffset: abs(position.rubberBand), dimension: dimension)
        self.fold = position.heldBounce + caught + (position.rubberBand < 0.0 ? -pull : pull)
        self.distance = travel
        self.bounce = position.heldBounce
        self.dimension = dimension
        self.open = canOpen ? 0.0 : travel

        if position.rubberBand < 0.0 {
            self.openEnd = (at: caught, pull: pull)
        } else if caught < self.open {
            self.openEnd = (at: caught, pull: 0.0)
        }

        if position.rubberBand > 0.0 {
            self.foldedEnd = (at: caught, pull: pull)
        } else if caught > travel {
            self.foldedEnd = (at: caught, pull: 0.0)
        }
    }

    /// Where the timers lie for a fold, the ends moved on as far as the finger has pushed them.
    ///
    /// - Parameter amount: How far the finger has the timers folded, from 0 open at the list's top, through the bounce
    ///   held, to the soonest timer's travel folded, with any pull past either end: negative past open and beyond
    ///   past folded.
    /// - Returns: How far open, held past the top and pulled past either end the timers are laid out.
    mutating func position(at amount: CGFloat) -> RunningTimersLayoutMetrics.Position {
        let folding = amount - bounce
        // Each end sees the finger no further than the other, so a catch past one end and pulled past the other holds.
        let opened = moveOpenEnd(to: min(folding, foldedEnd?.at ?? folding))
        let folded = max(opened, moveFoldedEnd(to: max(folding, opened)))
        let taken = min(max(0.0, bounce), max(0.0, opened - folding))

        return RunningTimersLayoutMetrics.Position(
            openness: 1.0 - folding.clamped(to: opened...folded) / distance,
            rubberBand: RubberBand.offset(
                at: folding + taken,
                pastEitherEndOf: opened...folded,
                dimension: dimension
            ),
            heldBounce: bounce - taken
        )
    }

    // An end goes back once the finger is on the near side of it and of its usual place, and moves out as it pulls on.
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
