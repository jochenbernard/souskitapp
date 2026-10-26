import SwiftUI

/// Lies behind a card and opens the share sheet for a recipe's file while one is given, pointing at the card where the
/// sheet is a popover.
///
/// The card's menu is built in UIKit, which has no place for a `ShareLink`, so the sheet opens from UIKit too.
struct RecipeShareSheet: UIViewRepresentable {
    /// The file to share, or `nil` while the sheet is closed.
    let fileURL: URL?

    /// Reports the sheet closed, whether or not it handed the file on.
    let dismiss: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false

        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.dismiss = dismiss

        guard
            let fileURL,
            !coordinator.isPresenting,
            let presentingController = Self.presentingController(of: view)
        else {
            return
        }

        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        controller.completionWithItemsHandler = { _, _, _, _ in
            coordinator.isPresenting = false
            coordinator.dismiss()
        }
        coordinator.isPresenting = true
        presentingController.present(controller, animated: true)
    }

    /// The view controller showing a view, or the one it presents on top.
    private static func presentingController(of view: UIView) -> UIViewController? {
        var controller = sequence(first: view as UIResponder, next: { $0.next })
            .lazy
            .compactMap({ $0 as? UIViewController })
            .first

        while let presentedController = controller?.presentedViewController {
            controller = presentedController
        }

        return controller
    }

    /// Whether the share sheet is open, and what its closing reports to.
    @MainActor
    final class Coordinator {
        var isPresenting = false
        var dismiss: @MainActor () -> Void = {}
    }
}
