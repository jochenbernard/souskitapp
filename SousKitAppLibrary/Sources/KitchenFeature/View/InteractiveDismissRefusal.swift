import SwiftUI

/// Keeps the presentation it lies in from every interactive dismissal, a drag beside a confirmation over it included.
struct InteractiveDismissRefusal: UIViewRepresentable {
    func makeUIView(context _: Context) -> RefusalView {
        RefusalView()
    }

    func updateUIView(_: RefusalView, context _: Context) {}

    final class RefusalView: UIView, UIAdaptivePresentationControllerDelegate {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard window != nil else {
                return
            }

            var responder: UIResponder? = self
            while let next = responder?.next, !(next is UIViewController) {
                responder = next
            }

            var controller = responder?.next as? UIViewController
            while let parent = controller?.parent {
                controller = parent
            }

            // With a confirmation over it, a zoom's swipe passes interactiveDismissDisabled() but not this delegate.
            guard
                let controller,
                controller.presentingViewController != nil,
                let presentationController = controller.presentationController,
                presentationController.delegate == nil
            else {
                return
            }

            presentationController.delegate = self
        }

        func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
            false
        }
    }
}
