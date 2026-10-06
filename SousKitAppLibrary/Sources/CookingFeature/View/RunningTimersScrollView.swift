import UIKit

/// The scroll view the running timers scroll in, which lets touches beside the folded stack through to the steps.
final class RunningTimersScrollView: UIScrollView {
    // How far a finger moves before a scroll view takes it as a swipe, which moves nothing.
    private static let swipeThreshold = 10.0

    /// Whether a touch at a point in the scroll view's bounds counts, or nil for every point counting.
    var isHittable: ((CGPoint) -> Bool)?

    /// Called with the bounds' size whenever it changes.
    var onSizeChange: ((CGSize) -> Void)?

    /// Called once the scroll view is in a window, or out of one.
    var onWindowChange: (() -> Void)?

    /// Where the last finger to touch the scroll view came down, in the window.
    private(set) var touchDownLocation: CGPoint?

    /// How far the content was scrolled when the last finger touched the scroll view.
    private(set) var touchDownContentOffset = CGPoint.zero

    private var lastSize = CGSize.zero

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != lastSize {
            lastSize = bounds.size
            onSizeChange?(bounds.size)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let isHittable, !isHittable(point) {
            return nil
        }

        if event?.type == .touches {
            touchDownLocation = convert(point, to: nil)
            touchDownContentOffset = contentOffset
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

    /// How far a swipe has gone along an axis since the finger came down, past the distance it takes to be a swipe,
    /// as a scroll view moves its content by once a swipe begins.
    ///
    /// Measured from the touch, since each swipe starts counting its own translation somewhere else.
    ///
    /// - Parameters:
    ///   - gestureRecognizer: The swipe.
    ///   - axis: The coordinate of the axis to measure along.
    /// - Returns: How far it has gone.
    func distanceMoved(by gestureRecognizer: UIGestureRecognizer, along axis: KeyPath<CGPoint, CGFloat>) -> CGFloat {
        guard let touchDownLocation else {
            return 0.0
        }

        let moved = gestureRecognizer.location(in: nil)[keyPath: axis] - touchDownLocation[keyPath: axis]
        return moved - min(Self.swipeThreshold, max(-Self.swipeThreshold, moved))
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
