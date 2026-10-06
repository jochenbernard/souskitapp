import SwiftUI

/// How the running timers scroll: their content sized in the scroll view, scrolling only while the list is open, and
/// the list held where it shows as the content shrinks, so a timer going near its end closes the gap from above
/// instead of the scrolling cutting back at once.
@MainActor
final class RunningTimersScrolling {
    private let scrollView: UIScrollView
    private let contentView: UIView
    private let motion: RunningTimersMotion
    private var contentHeight: CGFloat = 0.0
    private var settling: Task<Void, Never>?

    // How far the list's floor lies below the timers.
    private var hold: CGFloat {
        max(0.0, motion.scrollFloor - contentHeight)
    }

    /// - Parameters:
    ///   - scrollView: The scroll view the timers scroll in.
    ///   - contentView: The view showing the timers in it.
    ///   - motion: Where the list's floor goes, for the timers to be laid out above.
    init(
        scrollView: UIScrollView,
        contentView: UIView,
        motion: RunningTimersMotion
    ) {
        self.scrollView = scrollView
        self.contentView = contentView
        self.motion = motion
    }

    /// Sizes the content to the height the timers take, or holds it at the list's floor while that lies lower, until
    /// the timers have settled and the list lies within its end.
    ///
    /// - Parameter height: How tall the timers stand.
    func contentHeightDidChange(_ height: CGFloat) {
        contentHeight = height
        resizeContent()

        guard hold > 0.0 else {
            return
        }

        settling?.cancel()
        settling = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Animation.runningTimersSettlingDuration))

            guard !Task.isCancelled, let self else {
                return
            }

            settling = nil
            updateFloor()
        }
    }

    /// Lets the list scroll only while it is open, and undoes its scrolling as it closes.
    ///
    /// - Parameter isOpen: Whether the list is open.
    /// - Returns: How far the list was scrolled as it closed, or nothing as it opens.
    func listOpenDidChange(_ isOpen: Bool) -> CGFloat {
        scrollView.isScrollEnabled = isOpen
        releaseHold()

        guard !isOpen else {
            return 0.0
        }

        let offset = max(0.0, scrollView.contentOffset.y)
        scrollView.setContentOffset(.zero, animated: false)
        return offset
    }

    /// Lets a held list go, scrolling it back by as far as it was held as its timers rise by as much, so nothing
    /// moves, and sizes the content anew.
    func releaseHold() {
        settling?.cancel()
        settling = nil
        let held = hold
        // Cleared before scrolling back, which calls `updateFloor` again through `scrollViewDidScroll`.
        motion.scrollFloor = 0.0

        if held > 0.0 {
            scrollView.contentOffset.y = max(0.0, scrollView.contentOffset.y - held)
        }

        takeFloor()
        resizeContent()
    }

    /// Takes the bottom of what shows as the list's floor, short of a pull past the timers' end, or lets a held list
    /// go once it can without anything moving.
    func updateFloor() {
        guard hold > 0.0 else {
            takeFloor()
            return
        }

        let offset = scrollView.contentOffset.y
        // Released past its end, the list would lose its pull; a bounce settles there give or take rounding.
        let isWithinEnd = offset < scrollView.contentSize.height - scrollView.bounds.height + 1.0
        // Scrolled up into the hold, the list would show the gap above its timers.
        let isInHold = offset < hold

        if (settling == nil && isWithinEnd) || isInHold {
            releaseHold()
        }
    }

    private func takeFloor() {
        motion.scrollFloor = min(scrollView.contentOffset.y + scrollView.bounds.height, contentHeight)
    }

    private func resizeContent() {
        let size = CGSize(width: scrollView.bounds.width, height: contentHeight + hold)
        contentView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
    }
}
