import UIKit

/// The running app's idle timer, which every scene shares.
public struct ApplicationIdleTimer: IdleTimer {
    /// Creates an idle timer.
    public init() {}

    public func setDisabled(_ isDisabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isDisabled
    }
}
