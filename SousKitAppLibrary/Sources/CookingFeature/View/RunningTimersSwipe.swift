import SwiftUI

/// Takes a running timer away with a swipe to the left, as a notification is: the timer follows the finger, and let
/// go far enough it flies off and is cancelled, or springs back.
///
/// Any timer in the open list or the column can be swiped, and the front one of the folded stack.
@MainActor
final class RunningTimersSwipe: NSObject, UIGestureRecognizerDelegate {
    /// How far a timer slides, as a share of its width, before letting go takes it away.
    static let threshold = 0.5

    // How long a timer flown off waits to be gone before it comes back, as one that failed to cancel.
    private static let cancelTimeout = Duration.seconds(1)

    private let pan = UIPanGestureRecognizer()
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    private let scrollView: RunningTimersScrollView
    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel
    private let motion: RunningTimersMotion
    private let metrics: RunningTimersLayoutMetrics
    private let kind: RunningTimersPanel.Kind

    // The timer the finger has, where it lies in the panel's content, and whether letting go now takes it away.
    private var timer: RunningTimer?
    private var frame = CGRect.zero
    private var isArmed = false

    // The pull the finger took the timer up at, from where it was drawn.
    private var startPull: CGFloat = 0.0

    // Timers flown off and waiting to be cancelled, which a finger can no longer take back.
    private var leaving: Set<RunningTimer.ID> = []

    /// - Parameters:
    ///   - scrollView: The panel's scroll view, which the swipe is added to.
    ///   - metrics: Where the layout leaves where each timer lies.
    ///   - kind: How the panel shows the timers.
    init(
        scrollView: RunningTimersScrollView,
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel,
        motion: RunningTimersMotion,
        metrics: RunningTimersLayoutMetrics,
        kind: RunningTimersPanel.Kind
    ) {
        self.scrollView = scrollView
        self.presenter = presenter
        self.viewModel = viewModel
        self.motion = motion
        self.metrics = metrics
        self.kind = kind
        super.init()
        pan.addTarget(self, action: #selector(handlePan))
        pan.delegate = self
        scrollView.addGestureRecognizer(pan)
    }

    // Only sideways, and only on a timer that can be swiped.
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        guard scrollView.isSideways(pan), let target = swipeableTimer() else {
            return false
        }

        timer = target.timer
        frame = target.frame
        return true
    }

    // The list must be all the way open, or the stack all the way folded, where only the front timer shows itself.
    private func swipeableTimer() -> (timer: RunningTimer, frame: CGRect)? {
        guard let touchDown = scrollView.touchDownLocation else {
            return nil
        }

        let openness = metrics.presentedPosition.openness
        let isListed = kind == .column || (viewModel.isTimerListOpen && openness > 0.99)
        let isStacked = kind == .folding && !viewModel.isTimerListOpen && openness < 0.01
        let frames = isListed ? metrics.timerFrames : Array(metrics.timerFrames.prefix(isStacked ? 1 : 0))
        let point = scrollView.convert(touchDown, from: nil)

        guard
            let hit = frames.first(where: { $0.frame.contains(point) }),
            !leaving.contains(hit.id),
            let hitTimer = viewModel.runningTimers.first(where: { $0.id == hit.id })
        else {
            return nil
        }

        return (hitTimer, hit.frame)
    }

    @objc
    private func handlePan(_ pan: UIPanGestureRecognizer) {
        guard let timer else {
            return
        }

        switch pan.state {
        case .began:
            // Forgets the timers taken away, which are gone from the screen by now.
            motion.swipeOffsets = motion.swipeOffsets.filter({ viewModel.isRunning($0.key) })
            metrics.keepSwipeOffsets(of: Set(viewModel.runningTimers.map(\.id)))
            feedback.prepare()
            motion.swipedTimer = timer.id
            startPull = pull(forOffset: metrics.presentedSwipeOffset(of: timer.id))

            // Stops a spring still settling the timer where it is drawn, rather than carrying on under the finger.
            withAnimation(.halt) {
                move(timer, to: offset(forPull: startPull + scrollView.distanceMoved(by: pan, along: \.x)))
            }
        case .changed:
            move(timer, to: offset(forPull: startPull + scrollView.distanceMoved(by: pan, along: \.x)))
        case .ended:
            release(timer, velocity: pan.velocity(in: scrollView).x)
        case .cancelled, .failed:
            // The finger never let go, so the timer springs back even past the threshold.
            isArmed = false
            release(timer, velocity: 0.0)
        default:
            break
        }
    }

    // Past half the timer's width, letting go takes it away, which a tap is felt for either way across.
    private func move(_ timer: RunningTimer, to offset: CGFloat) {
        motion.swipeOffsets[timer.id] = offset

        let isPastThreshold = -offset >= frame.width * Self.threshold

        if isPastThreshold != isArmed {
            isArmed = isPastThreshold
            feedback.impactOccurred()
        }
    }

    // Left as far as the finger goes; right less and less the further, as a scroll view gives past its end.
    private func offset(forPull pull: CGFloat) -> CGFloat {
        guard pull > 0.0 else {
            return pull
        }

        return RubberBand.offset(forPull: pull, dimension: scrollView.bounds.width)
    }

    // How far the finger goes for the timer to slide an offset, the other way around from `offset(forPull:)`.
    private func pull(forOffset offset: CGFloat) -> CGFloat {
        guard offset > 0.0 else {
            return offset
        }

        return RubberBand.pull(forOffset: offset, dimension: scrollView.bounds.width)
    }

    // Let go past the threshold, the timer flies off at the finger's speed and is cancelled; short of it, it springs
    // back.
    private func release(_ timer: RunningTimer, velocity: CGFloat) {
        let offset = motion.swipeOffsets[timer.id] ?? 0.0
        // Only where the finger let go counts, not where its speed would have carried the timer.
        let takesAway = isArmed
        // Off the screen by as much as the timer keeps from its edge.
        let target = takesAway ? -(frame.maxX + frame.minX) : 0.0
        let delta = target - offset
        self.timer = nil
        motion.swipedTimer = nil
        isArmed = false

        // The finger's speed carries on only towards where the timer goes, so one springing back never swings on past
        // the threshold first, looking as if it were taken away.
        let initialVelocity = abs(delta) < 1.0 ? 0.0 : max(0.0, velocity / delta)

        withAnimation(.runningTimers(initialVelocity: initialVelocity)) {
            motion.swipeOffsets[timer.id] = target
        }

        guard takesAway else {
            return
        }

        leaving.insert(timer.id)

        // Cancelled once it is off the screen: a timer that goes away stops where it is, so mid-flight it would fade
        // there instead. Timed, so it does not hang on the animation reporting its end.
        Task {
            try? await Task.sleep(for: .seconds(Animation.runningTimersDuration))
            presenter.didSwipeAwayTimer(timer)
            try? await Task.sleep(for: Self.cancelTimeout)
            leaving.remove(timer.id)

            if viewModel.isRunning(timer.id) {
                withAnimation(.runningTimers) {
                    motion.swipeOffsets[timer.id] = 0.0
                }
            }
        }
    }
}
