import SwiftUI

/// Takes a running timer away with a swipe to the left, as a notification is: the timer follows the finger, and let
/// go far enough it flies off and is cancelled, or springs back.
///
/// Any timer in the open list or the column can be swiped, and the front one of the folded stack.
@MainActor
final class RunningTimersSwipe: NSObject, UIGestureRecognizerDelegate {
    /// How far a timer slides, as a share of its width, before letting go takes it away.
    static let threshold = 0.5

    // How far a finger moves before it counts as a swipe, as a scroll view takes it.
    private static let swipeThreshold = 10.0

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

        let openness = metrics.presentedOpenness
        let isListed = kind == .column || (viewModel.isTimerListOpen && openness > 0.99)
        let isStacked = kind == .folding && !viewModel.isTimerListOpen && openness < 0.01
        let frames = isListed ? metrics.timerFrames : Array(metrics.timerFrames.prefix(isStacked ? 1 : 0))
        let point = scrollView.convert(touchDown, from: nil)

        guard
            let hit = frames.first(where: { $0.frame.contains(point) }),
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
            motion.swipeOffsets = motion.swipeOffsets.filter({ isRunning($0.key) })
            feedback.prepare()
            motion.swipedTimer = timer.id
            move(timer, to: offset(for: distanceMoved(by: pan)))
        case .changed:
            move(timer, to: offset(for: distanceMoved(by: pan)))
        case .ended:
            release(timer, velocity: pan.velocity(in: scrollView).x)
        case .cancelled, .failed:
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

    // From where the finger came down, past the distance it takes to be a swipe.
    private func distanceMoved(by pan: UIPanGestureRecognizer) -> CGFloat {
        guard let touchDown = scrollView.touchDownLocation else {
            return 0.0
        }

        let moved = pan.location(in: nil).x - touchDown.x
        return moved - min(Self.swipeThreshold, max(-Self.swipeThreshold, moved))
    }

    // Left as far as the finger goes; right less and less the further, as a scroll view gives past its end.
    private func offset(for moved: CGFloat) -> CGFloat {
        guard moved > 0.0 else {
            return moved
        }

        return RubberBand.offset(forPull: moved, dimension: scrollView.bounds.width)
    }

    // Let go past the threshold, the timer flies off at the finger's speed and is cancelled; short of it, it springs
    // back.
    private func release(_ timer: RunningTimer, velocity: CGFloat) {
        let offset = motion.swipeOffsets[timer.id] ?? 0.0
        // Only where the finger let go counts, not where its speed would have carried the timer.
        let takesAway = -offset >= frame.width * Self.threshold
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

        // Cancelled once it is off the screen: a timer that goes away stops where it is, so mid-flight it would fade
        // there instead. Timed, so it does not hang on the animation reporting its end.
        Task {
            try? await Task.sleep(for: .seconds(Animation.runningTimersDuration))
            takeAway(timer)
        }
    }

    private func takeAway(_ timer: RunningTimer) {
        presenter.didSwipeAwayTimer(timer)
        bringBackIfStillRunning(timer)
    }

    private func bringBackIfStillRunning(_ timer: RunningTimer) {
        Task {
            try? await Task.sleep(for: Self.cancelTimeout)

            if isRunning(timer.id) {
                withAnimation(.runningTimers) {
                    motion.swipeOffsets[timer.id] = 0.0
                }
            }
        }
    }

    private func isRunning(_ id: RunningTimer.ID) -> Bool {
        viewModel.runningTimers.contains(where: { $0.id == id })
    }
}
