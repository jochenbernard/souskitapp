import SwiftUI

/// Keeps the presentation it lies in from every interactive dismissal, a drag beside a confirmation over it included.
struct InteractiveDismissRefusal: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> RefusalController {
        RefusalController()
    }

    func updateUIViewController(_: RefusalController, context _: Context) {}

    final class RefusalController: UIViewController, UIAdaptivePresentationControllerDelegate {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            // With a confirmation over it, a zoom's swipe passes interactiveDismissDisabled() but not this delegate.
            // A child's own presentationController is a new one, not the presentation's.
            guard
                let presentationController = presentingViewController?.presentedViewController?.presentationController,
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
