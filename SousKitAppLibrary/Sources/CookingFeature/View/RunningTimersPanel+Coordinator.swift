import SwiftUI
import UIKit

extension RunningTimersPanel {
    /// Scrolls the timers, turns a swipe past the list's top into folding it, and a swipe up the stack into opening it.
    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
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

        // The sum of the finger's travel and the scrolling it did before the fold, which stays put while the finger
        // only scrolls.
        private var foldBase: CGFloat = 0.0

        private lazy var hostingController = UIHostingController(rootView: makeContent())
        private lazy var scrolling = RunningTimersScrolling(
            scrollView: scrollView,
            contentView: hostingController.view,
            motion: motion,
            // The finger's travel counts the scrolling, so a hold let go under it would leave the fold that far behind.
            onScrollBack: { [weak self] distance in self?.foldBase -= distance }
        )

        private lazy var folding = RunningTimersFolding(
            scrollView: scrollView,
            presenter: presenter,
            motion: motion,
            metrics: metrics
        )

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
            // A swipe is taken up whether the timers scroll or not, since it folds the list or bounces the column.
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
            scrollView.isHittable = { [weak self] point in self?.isHittable(point) ?? true }
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
                onContentHeightChange: { [weak self] height in self?.scrolling.contentHeightDidChange(height) },
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
            // Releasing the hold also sizes the content to the new width, which it does not report.
            scrolling.releaseHold()
        }

        // While the list is closed, the steps get every touch but those on the stack, folding timers and fading button.
        private func isHittable(_ point: CGPoint) -> Bool {
            guard kind == .folding, !viewModel.isTimerListOpen else {
                return true
            }

            let stack = motion.stackFrame(in: region)

            // Timers above the top inset are faded out of sight, so the bar there keeps its taps as they fold.
            let isOnTimer = point.y >= topInset && metrics.timerFrames.contains(where: { $0.frame.contains(point) })

            let isOnButton = RunningTimersCollapseButton.isVisible(openness: metrics.presentedOpenness)
                && metrics.collapseButtonFrame?.contains(point) == true

            return stack.contains(point) || isOnTimer || isOnButton
        }

        // Closing undoes the scrolling, which the content keeps in its rows' places so they fold from where they were.
        private func listOpenDidChange(_ isOpen: Bool) -> CGFloat {
            folding.reset()
            return scrolling.listOpenDidChange(isOpen)
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
                folding.canOpen = true
                let start = scrollView.contentOffset.y > 0.0 ? 0.0 : scrollView.distanceMoved(by: pan, along: \.y)
                // A list caught bouncing past its top is held as far as it had bounced when the finger came down.
                let bounce = max(0.0, -scrollView.touchDownContentOffset.y)
                if bounce > 0.0 {
                    scrollView.contentOffset.y = 0.0
                }

                folding.caughtBounce = metrics.presentedHeldBounce + bounce
                let fold = metrics.presentedFold + bounce + (fits ? start : max(0.0, start))
                foldBase = travel - fold
                folding.setFold(fold)
            case .changed:
                if folding.fold <= 0.0, scrollView.contentOffset.y > 0.0 {
                    foldBase = travel
                }

                folding.setFold(fits ? travel - foldBase : max(0.0, travel - foldBase))
            case .ended, .cancelled, .failed:
                folding.release(velocity: pan.velocity(in: scrollView).y)
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
                folding.canOpen = viewModel.canOpenTimerList
                folding.caughtBounce = metrics.presentedHeldBounce
                let fold = metrics.presentedFold + scrollView.distanceMoved(by: pan, along: \.y)
                foldBase = travel - fold
                folding.setFold(fold)
            case .changed:
                folding.setFold(travel - foldBase)
            case .ended, .cancelled, .failed:
                folding.releaseOpening(velocity: pan.velocity(in: scrollView).y)
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

        // The column scrolls and bounces as any scroll view. The list goes past its top only on a swipe's momentum,
        // and bounces back from there; under the finger, the travel past the top folds it instead. It is held at the
        // top while the finger has it folded, so its way back up takes the fold back before it scrolls. A list that
        // fits its room does not scroll at all.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.y
            let fits = scrollView.contentSize.height <= scrollView.bounds.height
            let isHeld = scrollView.isTracking || folding.fold != 0.0

            if
                kind == .folding,
                (offset < 0.0 && isHeld) || (offset > 0.0 && (fits || (folding.fold > 0.0 && scrollView.isTracking)))
            {
                scrollView.contentOffset.y = 0.0
            }

            motion.scrollOffset = scrollView.contentOffset.y
            scrolling.updateFloor()
        }

        func scrollViewWillEndDragging(
            _: UIScrollView,
            withVelocity _: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            if folding.fold != 0.0 {
                targetContentOffset.pointee.y = 0.0
            }
        }
    }
}
