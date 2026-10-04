import SwiftUI
import UIKit

extension RunningTimersPanel {
    /// Scrolls the timers, turns a swipe past the list's top into folding it, and a swipe up the stack into opening it.
    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        // How far ahead of the finger a swipe is taken to go on, to decide whether it folds the list, and how far a
        // swipe folds a tall list before letting go closes it.
        private static let projection = 0.2
        private static let closeDistance = 120.0
        let scrollView = RunningTimersScrollView()

        // The scroll view takes no swipes while the list is closed, so the stack has one of its own to open it.
        private let openingPan = UIPanGestureRecognizer()

        // A timer has a swipe of its own too, sideways, to take it away.
        private var swipe: RunningTimersSwipe?

        private let presenter: CookingFeaturePresenterProtocol
        private let viewModel: CookingFeatureViewModel
        private let motion: RunningTimersMotion
        private let kind: Kind
        private let metrics = RunningTimersLayoutMetrics()
        private var region = CGSize.zero

        // How far the finger has folded the list, and the sum of the finger's travel and the scrolling it did before
        // the fold, which stays put while the finger only scrolls.
        private var fold: CGFloat = 0.0
        private var foldBase: CGFloat = 0.0

        // Whether the finger can open the list, which a single timer has none of, so it only pulls the stack past.
        private var canOpen = true

        private lazy var hostingController = UIHostingController(rootView: makeContent())

        var topInset: CGFloat = 0.0 {
            didSet {
                if topInset != oldValue {
                    hostingController.rootView = makeContent()
                }
            }
        }

        init(
            presenter: CookingFeaturePresenterProtocol,
            viewModel: CookingFeatureViewModel,
            motion: RunningTimersMotion,
            kind: Kind
        ) {
            self.presenter = presenter
            self.viewModel = viewModel
            self.motion = motion
            self.kind = kind
            super.init()
            configureScrollView()
        }

        private func configureScrollView() {
            scrollView.delegate = self
            // A swipe is taken up whether the list scrolls or not, since it folds the list either way.
            scrollView.alwaysBounceVertical = true
            scrollView.clipsToBounds = false
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.delaysContentTouches = false
            scrollView.isScrollEnabled = kind == .column
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan))
            openingPan.addTarget(self, action: #selector(handleOpeningPan))
            openingPan.delegate = self
            scrollView.addGestureRecognizer(openingPan)
            swipe = RunningTimersSwipe(
                scrollView: scrollView,
                presenter: presenter,
                viewModel: viewModel,
                motion: motion,
                metrics: metrics,
                kind: kind
            )
            scrollView.hittableRect = { [weak self] in self?.hittableRect() }
            scrollView.onSizeChange = { [weak self] size in self?.regionDidChange(size) }
            scrollView.onWindowChange = { [weak self] in self?.attachHostingController() }

            hostingController.view.backgroundColor = .clear
            hostingController.safeAreaRegions = []
            scrollView.addSubview(hostingController.view)
        }

        private func makeContent() -> RunningTimersPanelContent {
            RunningTimersPanelContent(
                presenter: presenter,
                viewModel: viewModel,
                motion: motion,
                kind: kind,
                region: region,
                topInset: topInset,
                metrics: metrics,
                onContentHeightChange: { [weak self] height in self?.contentHeightDidChange(height) },
                onListOpenChange: { [weak self] isOpen in self?.listOpenDidChange(isOpen) ?? 0.0 }
            )
        }

        // Presenting from the content, a confirmation included, takes a place among the screen's view controllers.
        private func attachHostingController() {
            // Out of the window, the panel lets its place go, or every panel the screen ever showed stays a child.
            guard scrollView.window != nil else {
                hostingController.willMove(toParent: nil)
                hostingController.removeFromParent()
                return
            }

            guard hostingController.parent == nil else {
                return
            }

            var responder: UIResponder? = scrollView

            while let next = responder?.next {
                if let parent = next as? UIViewController {
                    parent.addChild(hostingController)
                    hostingController.didMove(toParent: parent)
                    return
                }

                responder = next
            }
        }

        private func regionDidChange(_ size: CGSize) {
            region = size
            hostingController.rootView = makeContent()
        }

        private func contentHeightDidChange(_ height: CGFloat) {
            let size = CGSize(width: region.width, height: height)
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            scrollView.contentSize = size
        }

        // Only the stack takes touches while the list is closed; beside it, they reach the steps.
        private func hittableRect() -> CGRect? {
            guard kind == .folding, !viewModel.isTimerListOpen else {
                return nil
            }

            return CGRect(
                x: 0.0,
                y: region.height - motion.stackHeight,
                width: region.width,
                height: motion.stackHeight
            )
        }

        // The list scrolls only while it is open. Closing it undoes its scrolling, which the content keeps in its
        // rows' places so they fold from where they were.
        private func listOpenDidChange(_ isOpen: Bool) -> CGFloat {
            scrollView.isScrollEnabled = isOpen
            fold = 0.0

            guard !isOpen else {
                return 0.0
            }

            let offset = max(0.0, scrollView.contentOffset.y)
            scrollView.setContentOffset(.zero, animated: false)
            return offset
        }

        // The finger scrolls the list until it reaches its top, and folds it from there: what the finger travels past
        // the scrolling it did goes into the fold, and back out of it when the finger comes back up.
        @objc
        private func handlePan(_ pan: UIPanGestureRecognizer) {
            guard kind == .folding else {
                return
            }

            let translation = pan.translation(in: scrollView).y
            let travel = translation + max(0.0, scrollView.contentOffset.y)
            // A list that scrolls takes a swipe up past its top as scrolling, one that fits as pulling it past.
            let fits = scrollView.contentSize.height <= scrollView.bounds.height

            switch pan.state {
            case .began:
                // A scrolled list scrolls the swipe's start; at its top, the start goes into the fold.
                canOpen = true
                let start = scrollView.contentOffset.y > 0.0 ? 0.0 : scrollView.distanceMoved(by: pan, along: \.y)
                fold = presentedFold() + (fits ? start : max(0.0, start))
                foldBase = travel - fold
                setFold(fold)
            case .changed:
                if fold <= 0.0, scrollView.contentOffset.y > 0.0 {
                    foldBase = travel
                }

                setFold(fits ? travel - foldBase : max(0.0, travel - foldBase))
            case .ended, .cancelled, .failed:
                release(velocity: pan.velocity(in: scrollView).y)
            default:
                break
            }
        }

        // The finger opens the stack from where it is, as far as it has travelled up, and back down as it comes back.
        @objc
        private func handleOpeningPan(_ pan: UIPanGestureRecognizer) {
            let travel = pan.translation(in: scrollView).y

            switch pan.state {
            case .began:
                canOpen = viewModel.canOpenTimerList
                fold = presentedFold() + scrollView.distanceMoved(by: pan, along: \.y)
                foldBase = travel - fold
                setFold(fold)
            case .changed:
                setFold(travel - foldBase)
            case .ended, .cancelled, .failed:
                releaseOpening(velocity: pan.velocity(in: scrollView).y)
            default:
                break
            }
        }

        // Only a swipe up or down a folded stack opens it or pulls it past; the stack takes any other touch as before.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard gestureRecognizer === openingPan else {
                return true
            }

            // By how far the finger went rather than how fast, which a slow start leaves at nothing either way.
            return kind == .folding && !viewModel.isTimerListOpen && !scrollView.isSideways(openingPan)
        }

        // The fold the finger takes the timers up at, from where they are laid out: how far they are folded, and the
        // pull past it of whatever is left of a pull, which a spring settling back from one overshoots either way.
        private func presentedFold() -> CGFloat {
            let rubberBand = metrics.presentedRubberBand
            let pull = RubberBand.pull(forOffset: abs(rubberBand), dimension: scrollView.bounds.height)

            return (1.0 - metrics.presentedOpenness) * metrics.foldDistance + (rubberBand < 0.0 ? -pull : pull)
        }

        // Within the timers' two ends the finger moves them as far as it goes; past either, less and less the further.
        private func setFold(_ amount: CGFloat) {
            let distance = metrics.foldDistance
            let open = canOpen ? 0.0 : distance
            let height = scrollView.bounds.height
            fold = amount
            motion.openness = 1.0 - min(1.0, max(open, amount) / distance)
            motion.rubberBand = if amount < open {
                -RubberBand.offset(forPull: open - amount, dimension: height)
            } else if amount > distance {
                RubberBand.offset(forPull: amount - distance, dimension: height)
            } else {
                0.0
            }
        }

        // Settles the timers open or folded on the timers' spring, carrying on at the finger's speed.
        private func settle(isOpen: Bool, velocity: CGFloat) {
            let target = isOpen ? 1.0 : 0.0
            let delta = target - motion.openness
            let remaining = abs(delta) < 0.05 ? (delta < 0.0 ? -0.05 : 0.05) : delta
            fold = 0.0

            withAnimation(.runningTimers(initialVelocity: -velocity / metrics.foldDistance / remaining)) {
                motion.openness = target
            }

            withAnimation(.runningTimers) {
                motion.rubberBand = 0.0
            }
        }

        // Let go, the list folds or opens back up from the speed the finger had, whichever it is closer to going by.
        // The fold starts here rather than on the list closing, so nothing waits between the finger and the fold.
        private func release(velocity: CGFloat) {
            guard fold != 0.0 else {
                return
            }

            let distance = metrics.foldDistance
            let closes = fold + velocity * Self.projection > min(distance / 2.0, Self.closeDistance)
            settle(isOpen: !closes, velocity: velocity)

            if closes {
                presenter.didCloseTimerList()
            }
        }

        // Let go, the stack opens or folds back from the speed the finger had, the way a swipe down the list decides.
        private func releaseOpening(velocity: CGFloat) {
            let distance = metrics.foldDistance
            let opened = distance - fold - velocity * Self.projection
            let opens = canOpen && opened > min(distance / 2.0, Self.closeDistance)
            settle(isOpen: opens, velocity: velocity)

            if opens {
                presenter.didOpenTimerList()
            }
        }

        // Never past the top, where the finger's travel folds the list instead, and held at the top while the finger
        // has the list folded, so its way back up takes the fold back before it scrolls. A list that fits its room
        // does not scroll at all.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.y
            let fits = scrollView.contentSize.height <= scrollView.bounds.height

            if offset < 0.0 || (offset > 0.0 && (fits || (fold > 0.0 && scrollView.isTracking))) {
                scrollView.contentOffset.y = 0.0
            }

            motion.scrollOffset = scrollView.contentOffset.y
        }

        func scrollViewWillEndDragging(
            _: UIScrollView,
            withVelocity _: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            if fold > 0.0 {
                targetContentOffset.pointee.y = 0.0
            }
        }
    }
}
