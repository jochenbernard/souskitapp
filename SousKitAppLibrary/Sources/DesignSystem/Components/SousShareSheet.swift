import SwiftUI

/// Lies behind a view and opens the share sheet for a file while one is given, pointing at the view, or at a button in
/// the bar of the screen showing the view, where the sheet is a popover.
///
/// The sheet takes a file already on the device, so it opens showing the file rather than an app's icon.
public struct SousShareSheet: UIViewRepresentable {
    /// The file to share, or `nil` while the sheet is closed.
    let fileURL: URL?

    /// The title of the bar button the popover points at, or `nil` to point at the view.
    let barButtonTitle: String?

    /// Reports the sheet closed, whether or not it handed the file on.
    let dismiss: @MainActor () -> Void

    /// Creates the sheet's anchor.
    ///
    /// - Parameters:
    ///   - fileURL: The file to share, or `nil` while the sheet is closed.
    ///   - barButtonTitle: The title of the button in the screen's bar the popover points at, or `nil` to point at
    ///     the view the sheet lies behind.
    ///   - dismiss: Reports the sheet closed, whether or not it handed the file on.
    public init(
        fileURL: URL?,
        barButtonTitle: String? = nil,
        dismiss: @escaping @MainActor () -> Void
    ) {
        self.fileURL = fileURL
        self.barButtonTitle = barButtonTitle
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
        coordinator.view = view
        coordinator.barButtonTitle = barButtonTitle
        coordinator.dismiss = dismiss

        guard
            let fileURL,
            !coordinator.isPresenting,
            let presentingController = Self.presentingController(of: view)
        else {
            return
        }

        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.popoverPresentationController?.delegate = coordinator
        controller.completionWithItemsHandler = { _, _, _, _ in
            coordinator.isPresenting = false
            coordinator.dismiss()
        }
        coordinator.isPresenting = true
        presentingController.present(controller, animated: true)
    }

    /// The button carrying a title in the bar of the screen showing a view.
    private static func barButtonItem(titled title: String?, of view: UIView) -> UIBarButtonItem? {
        guard let title else {
            return nil
        }

        // A toolbar button is drawn by UIKit, outside the view it is declared in, so it is found by its title.
        return sequence(first: view as UIResponder, next: { $0.next })
            .lazy
            .compactMap({ $0 as? UIViewController })
            .flatMap({ $0.navigationItem.leadingItemGroups + $0.navigationItem.trailingItemGroups })
            .flatMap(\.barButtonItems)
            .first(where: { $0.title == title })
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

    /// What the popover points at: the bar button while a bar draws it, else the view while a window shows it.
    static func sourceItem(
        barButtonItem: UIBarButtonItem?,
        view: UIView
    ) -> UIPopoverPresentationControllerSourceItem? {
        guard let window = view.window else {
            return nil
        }

        // A button no bar has drawn has an empty frame, and a popover pointing at it stops the app.
        if let barButtonItem, let frame = barButtonItem.frame(in: window), !frame.isEmpty {
            return barButtonItem
        }

        return view
    }

    /// Whether the share sheet is open, what its popover points at, and what its closing reports to.
    @MainActor
    public final class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
        var isPresenting = false
        weak var view: UIView?
        var barButtonTitle: String?
        var dismiss: @MainActor () -> Void = {}

        // The anchor is found as the popover presents, when the bar button must already be drawn.
        public func prepareForPopoverPresentation(_ popover: UIPopoverPresentationController) {
            let sourceItem = view.flatMap { view in
                SousShareSheet.sourceItem(
                    barButtonItem: SousShareSheet.barButtonItem(titled: barButtonTitle, of: view),
                    view: view
                )
            }

            if let sourceItem {
                popover.sourceItem = sourceItem
            } else {
                // A popover pointing at nothing stops the app, so it stands in the middle of the screen instead.
                let screenView: UIView = popover.presentingViewController.view
                popover.sourceView = screenView
                popover.sourceRect = CGRect(
                    x: screenView.bounds.midX,
                    y: screenView.bounds.midY,
                    width: 0.0,
                    height: 0.0
                )
                popover.permittedArrowDirections = []
            }
        }
    }
}

#Preview {
    Text(verbatim: "Crepes")
        .background {
            SousShareSheet(fileURL: nil, dismiss: {})
        }
}
