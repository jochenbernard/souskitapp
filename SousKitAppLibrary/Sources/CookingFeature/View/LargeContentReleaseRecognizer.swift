import UIKit.UIGestureRecognizerSubclass

/// Recognizes a finger lifting while the large content viewer shows what it held.
///
/// The viewer takes the touch from a SwiftUI button once it shows, and presses nothing as the finger lifts. This
/// recognizer stands beside both, and fails at once where no viewer follows the touch, as below the accessibility text
/// sizes.
final class LargeContentReleaseRecognizer: UIGestureRecognizer {
    // The viewer's own recognizer, for as long as it follows the touch this one follows.
    private weak var viewer: UIGestureRecognizer?

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent) {
        viewer = touches
            .flatMap { $0.gestureRecognizers ?? [] }
            .first(where: showsLargeContent)

        if viewer == nil {
            state = .failed
        }
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent) {
        switch viewer?.state {
        case .began, .changed, .ended:
            state = .ended

        default:
            state = .failed
        }
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent) {
        state = .failed
    }

    // Neither the viewer nor the button's own press is kept from the touch.
    override func canPrevent(_: UIGestureRecognizer) -> Bool {
        false
    }

    override func canBePrevented(by _: UIGestureRecognizer) -> Bool {
        false
    }

    override func reset() {
        super.reset()
        viewer = nil
    }

    // Whether a large content viewer on the recognizer's view shows and hides by it.
    private func showsLargeContent(_ recognizer: UIGestureRecognizer) -> Bool {
        recognizer.view?.interactions.contains { interaction in
            (interaction as? UILargeContentViewerInteraction)?.gestureRecognizerForExclusionRelationship === recognizer
        } ?? false
    }
}
