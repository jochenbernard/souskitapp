import SwiftUI

/// Folds the running timers as far as a finger takes them, and once it lets go, settles them open or folded and opens
/// or closes the list by how far and how fast the finger went.
@MainActor
final class RunningTimersFolding {
    // How far ahead of the finger a swipe is taken to go on, to decide whether it folds the list, and how far a
    // swipe folds a tall list before letting go closes it.
    private static let projection = 0.2
    private static let closeDistance = 120.0

    /// How far the finger has folded the list, down from open for positive values.
    private(set) var fold: CGFloat = 0.0

    /// How far past its top the finger caught the list bouncing, which the fold takes up before it folds the rows.
    var caughtBounce: CGFloat = 0.0

    /// Whether the finger can open the list, which a single timer has none of, so it only pulls the stack past.
    var canOpen = true

    private let scrollView: UIScrollView
    private let presenter: CookingFeaturePresenterProtocol
    private let motion: RunningTimersMotion
    private let metrics: RunningTimersLayoutMetrics

    /// - Parameters:
    ///   - scrollView: The scroll view the timers scroll in.
    ///   - metrics: Where the layout leaves how far the timers fold.
    init(
        scrollView: UIScrollView,
        presenter: CookingFeaturePresenterProtocol,
        motion: RunningTimersMotion,
        metrics: RunningTimersLayoutMetrics
    ) {
        self.scrollView = scrollView
        self.presenter = presenter
        self.motion = motion
        self.metrics = metrics
    }

    /// Moves the timers as far as the finger within their two ends, and less and less the further past either. A
    /// caught bounce moves every timer alike, as it did while bouncing, until the fold has taken it up.
    ///
    /// - Parameter amount: How far the finger has folded the list, down from open for positive values.
    func setFold(_ amount: CGFloat) {
        let distance = metrics.foldDistance(holding: caughtBounce)
        let open = canOpen ? 0.0 : distance
        let height = scrollView.bounds.height
        let held = min(max(0.0, amount), caughtBounce)
        let folded = amount - held
        fold = amount
        motion.heldBounce = held
        motion.openness = 1.0 - min(1.0, max(open, folded) / distance)
        motion.rubberBand = RubberBand.offset(
            at: folded,
            pastEitherEndOf: open...distance,
            dimension: height
        )
    }

    /// Leaves the timers to the list opening or closing.
    func reset() {
        fold = 0.0
    }

    /// Folds the list or opens it back up from the speed the finger had, whichever it is closer to going by.
    ///
    /// - Parameter velocity: How fast the finger went down as it let go.
    func release(velocity: CGFloat) {
        guard fold != 0.0 else {
            return
        }

        let distance = metrics.foldDistance
        let closes = fold + velocity * Self.projection > min(distance / 2.0, Self.closeDistance)
        // The fold starts here rather than on the list closing, so nothing waits between the finger and the fold.
        settle(isOpen: !closes, velocity: velocity)

        if closes {
            presenter.didCloseTimerList()
        }
    }

    /// Opens the stack or folds it back from the speed the finger had, the way a swipe down the list decides.
    ///
    /// - Parameter velocity: How fast the finger went down as it let go.
    func releaseOpening(velocity: CGFloat) {
        let distance = metrics.foldDistance
        let opened = distance - fold - velocity * Self.projection
        let opens = canOpen && opened > min(distance / 2.0, Self.closeDistance)
        settle(isOpen: opens, velocity: velocity)

        if opens {
            presenter.didOpenTimerList()
        }
    }

    // Settles the timers open or folded on the timers' spring, carrying on at the finger's speed.
    private func settle(isOpen: Bool, velocity: CGFloat) {
        let target = isOpen ? 1.0 : 0.0
        let delta = target - motion.openness
        let remaining = abs(delta) < 0.05 ? (delta < 0.0 ? -0.05 : 0.05) : delta
        let distance = metrics.foldDistance(holding: caughtBounce)
        fold = 0.0

        withAnimation(.runningTimers(initialVelocity: -velocity / distance / remaining)) {
            motion.openness = target
        }

        withAnimation(.runningTimers) {
            motion.rubberBand = 0.0
            motion.heldBounce = 0.0
        }
    }
}
