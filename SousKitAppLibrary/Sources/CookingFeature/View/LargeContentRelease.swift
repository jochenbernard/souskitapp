import SwiftUI

/// Presses a view as the finger lifts from it with the view's large content showing, as a toolbar button is pressed.
///
/// A finger that slid off the view first presses nothing.
struct LargeContentRelease: UIGestureRecognizerRepresentable {
    private let size: CGSize
    private let isEnabled: Bool
    private let action: () -> Void

    /// - Parameters:
    ///   - size: How large the view is.
    ///   - isEnabled: Whether the view can be pressed.
    ///   - action: What pressing the view does.
    init(
        size: CGSize,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    func makeUIGestureRecognizer(context _: Context) -> LargeContentReleaseRecognizer {
        LargeContentReleaseRecognizer()
    }

    func handleUIGestureRecognizerAction(_ recognizer: LargeContentReleaseRecognizer, context: Context) {
        let bounds = CGRect(origin: .zero, size: size)

        guard
            isEnabled,
            recognizer.state == .ended,
            bounds.contains(context.converter.localLocation)
        else {
            return
        }

        action()
    }
}
