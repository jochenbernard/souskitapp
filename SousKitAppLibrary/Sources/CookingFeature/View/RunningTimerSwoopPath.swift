import SwiftUI

/// The way a running timer swoops from the front of the stack to its place behind the others.
enum RunningTimerSwoopPath {
    /// Where a swooping timer is on its way.
    ///
    /// - Parameters:
    ///   - progress: How far the timer is on its way, from 0 in front to 1 in its place.
    ///   - start: The front of the stack.
    ///   - end: The timer's place in the stack.
    /// - Returns: The timer's frame.
    static func rect(
        at progress: Double,
        from start: CGRect,
        to end: CGRect
    ) -> CGRect {
        // One curve from the front over the top of the stack and down into the timer's place, halfway along just
        // above the soonest timer and clear of the stack, where it passes from in front of the others to behind them.
        let top = start.offsetBy(dx: 0.0, dy: -(start.height + RunningTimersLayout.spacing))

        func along(_ value: (CGRect) -> CGFloat) -> CGFloat {
            let control = 2.0 * value(top) - (value(start) + value(end)) / 2.0
            let remaining = 1.0 - progress

            return remaining * remaining * value(start) + 2.0 * remaining * progress * control
                + progress * progress * value(end)
        }

        return CGRect(
            x: along(\.minX),
            y: along(\.minY),
            width: along(\.width),
            height: along(\.height)
        )
    }
}
