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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?()
    }
}
