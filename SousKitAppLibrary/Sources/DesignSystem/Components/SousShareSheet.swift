import SwiftUI

/// Lies behind a view and opens the share sheet for a file while one is given, pointing at the view, or at a button in
/// the bar of the screen showing the view, where the sheet is a popover.
///
/// The sheet takes a file already on the device, so it opens showing the file rather than an app's icon.
public struct SousShareSheet: UIViewRepresentable {
    /// The file to share, or `nil` while the sheet is closed.
    let fileURL: URL?

    /// The accessibility identifier of the bar button the popover points at, or `nil` to point at the view.
    let barButtonID: String?

    /// Reports the sheet closed, whether or not it handed the file on.
    let dismiss: @MainActor () -> Void

    /// Creates the sheet's anchor.
    ///
    /// - Parameters:
    ///   - fileURL: The file to share, or `nil` while the sheet is closed.
    ///   - barButtonID: The accessibility identifier of the button in the screen's bar the popover points at, or
    ///     `nil` to point at the view the sheet lies behind.
    ///   - dismiss: Reports the sheet closed, whether or not it handed the file on.
    public init(
        fileURL: URL?,
        barButtonID: String? = nil,
        dismiss: @escaping @MainActor () -> Void
    ) {
        self.fileURL = fileURL
        self.barButtonID = barButtonID
        self.dismiss = dismiss
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false

        return view
    }

    public func updateUIView(_ view: UIView, context: Context) {
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
        if let barButtonItem = barButtonItem(of: view) {
            controller.popoverPresentationController?.sourceItem = barButtonItem
        } else {
            controller.popoverPresentationController?.sourceView = view
        }

        controller.completionWithItemsHandler = { _, _, _, _ in
            coordinator.isPresenting = false
            coordinator.dismiss()
        }
        coordinator.isPresenting = true
        presentingController.present(controller, animated: true)
    }

    /// The button carrying ``barButtonID`` in the bar of the screen showing a view.
    private func barButtonItem(of view: UIView) -> UIBarButtonItem? {
        guard let barButtonID else {
            return nil
        }

        // A toolbar button is drawn by UIKit, outside the view it is declared in, so it is found by its identifier.
        return sequence(first: view as UIResponder, next: { $0.next })
            .lazy
            .compactMap({ $0 as? UIViewController })
            .flatMap({ $0.navigationItem.leadingItemGroups + $0.navigationItem.trailingItemGroups })
            .flatMap(\.barButtonItems)
            .first(where: { $0.accessibilityIdentifier == barButtonID })
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
    public final class Coordinator {
        var isPresenting = false
        var dismiss: @MainActor () -> Void = {}
    }
}

#Preview {
    Text(verbatim: "Crepes")
        .background {
            SousShareSheet(fileURL: nil, dismiss: {})
        }
}
