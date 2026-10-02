import UIKit

/// The scroll view the running timers scroll in, which lets touches beside the folded stack through to the steps.
final class RunningTimersScrollView: UIScrollView {
    /// Where touches count, in the scroll view's bounds, or nil for everywhere in them.
    var hittableRect: (() -> CGRect?)?

    /// Called with the bounds' size whenever it changes.
    var onSizeChange: ((CGSize) -> Void)?

    /// Called once the scroll view is in a window, or out of one.
    var onWindowChange: (() -> Void)?

    /// Where the last finger to touch the scroll view came down, in the window.
    private(set) var touchDownLocation: CGPoint?

    private var lastSize = CGSize.zero

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != lastSize {
            lastSize = bounds.size
            onSizeChange?(bounds.size)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let rect = hittableRect?(), !rect.contains(point) {
            return nil
        }

        if event?.type == .touches {
            touchDownLocation = convert(point, to: nil)
        }

        return super.hitTest(point, with: event)
    }

    /// Whether a swipe has gone more sideways than up or down since the finger came down.
    ///
    /// Read as the swipe begins, which is when its own translation starts again from nothing.
    ///
    /// - Parameter gestureRecognizer: The swipe.
    /// - Returns: Whether it has gone more sideways.
    func isSideways(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let touchDownLocation else {
            return false
        }

        let location = gestureRecognizer.location(in: nil)
        return abs(location.x - touchDownLocation.x) > abs(location.y - touchDownLocation.y)
    }

    // The timers scroll up and down only; a swipe sideways is a timer's, to take it away.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer, isSideways(gestureRecognizer) {
            return false
        }

        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?()
    }
}
