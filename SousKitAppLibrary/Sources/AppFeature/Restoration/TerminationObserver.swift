import UIKit

/// Calls back as the app is being quit, for as long as it is held.
///
/// SwiftUI delivers no updates while the app is being quit, so a view's `onReceive` never hears it.
@MainActor
final class TerminationObserver {
    private let observer: NSObjectProtocol

    /// Creates an observer.
    ///
    /// - Parameter onTerminate: What runs as the app is being quit.
    init(onTerminate: @escaping @MainActor () -> Void) {
        self.observer = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { _ in
            // Posted on the main thread, and run at once, before the app is gone.
            MainActor.assumeIsolated(onTerminate)
        }
    }

    isolated deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
