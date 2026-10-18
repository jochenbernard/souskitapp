import SwiftUI

/// Lays the popover over the window out again whenever the view it points at moves.
///
/// UIKit moves a popover to where its source moved only as it lays the popover out, which a resize of the window
/// brings, and a change of the text size that moves the source does not.
struct PopoverSourceTracking: UIViewRepresentable {
    // Read by no one, but a change of it updates the view, which lays the popover out.
    private let sourceFrame: CGRect

    /// - Parameter sourceFrame: Where the view the popover points at stands.
    init(sourceFrame: CGRect) {
        self.sourceFrame = sourceFrame
    }

    func makeUIView(context _: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ view: UIView, context _: Context) {
        // SwiftUI hands the popover its new source only after this update.
        Task { @MainActor [weak view] in
            var controller = view?.window?.rootViewController

            while let presented = controller?.presentedViewController {
                controller = presented
            }

            let container = controller?.popoverPresentationController?.containerView
            container?.setNeedsLayout()
            container?.layoutIfNeeded()
        }
    }
}
