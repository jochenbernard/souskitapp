import SwiftUI

/// Hands VoiceOver the sheet it lies in, which it never reads on its own over the cooking screen's cover.
struct VoiceOverHandoff: UIViewRepresentable {
    func makeUIView(context _: Context) -> HandoffView {
        HandoffView()
    }

    func updateUIView(_: HandoffView, context _: Context) {}

    final class HandoffView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard window != nil else {
                return
            }

            var responder: UIResponder? = self
            while let next = responder?.next, !(next is UIViewController) {
                responder = next
            }

            // Reading the sheet's screen builds its elements, which lets the length asked for in onAppear take focus.
            UIAccessibility.post(notification: .layoutChanged, argument: (responder?.next as? UIViewController)?.view)
        }
    }
}
