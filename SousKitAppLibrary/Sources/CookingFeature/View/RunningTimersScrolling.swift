import SwiftUI

/// How the running timers scroll: their content sized in the scroll view, scrolling only while the list is open, and
/// the list held where it rests as the content shrinks, so a timer going near its end closes the gap from above
/// instead of the scrolling cutting back at once.
@MainActor
final class RunningTimersScrolling {
    // How long a hold lasts, by when the timers' spring has settled.
    private static let holdDuration = Animation.runningTimersDuration * 2.0

    private let scrollView: UIScrollView
    private let contentView: UIView
    private let motion: RunningTimersMotion
    private var contentHeight: CGFloat = 0.0
    private var release: Task<Void, Never>?

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
    /// the timers have settled.
    ///
    /// - Parameter height: How tall the timers stand.
    func contentHeightDidChange(_ height: CGFloat) {
        contentHeight = height
        resizeContent()

        guard motion.scrollFloor > height else {
            return
        }

        release?.cancel()
        release = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.holdDuration))

            if !Task.isCancelled {
                self?.releaseHold()
            }
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
        release?.cancel()
        release = nil
        let hold = motion.scrollFloor - contentHeight

        if hold > 0.0 {
            scrollView.contentOffset.y = max(0.0, scrollView.contentOffset.y - hold)
        }

        updateFloor()
        resizeContent()
    }

    /// Takes the bottom of what shows as the list's floor while it rests, and none while a finger or a fling moves it.
    func updateFloor() {
        let floor = if scrollView.isDragging || scrollView.isDecelerating {
            0.0
        } else {
            scrollView.contentOffset.y + scrollView.bounds.height
        }

        if motion.scrollFloor != floor {
            motion.scrollFloor = floor
        }
    }

    private func resizeContent() {
        let size = CGSize(width: scrollView.bounds.width, height: max(contentHeight, motion.scrollFloor))
        contentView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
    }
}
