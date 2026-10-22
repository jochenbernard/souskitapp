import SwiftUI

/// Reports when the screen it lies in has appeared, its push finished and the screen on display, which `onAppear`
/// reports before the screen is drawn.
struct AppearanceReport: UIViewControllerRepresentable {
    let action: @MainActor () -> Void

    func makeUIViewController(context _: Context) -> ReportController {
        ReportController(action: action)
    }

    func updateUIViewController(_ controller: ReportController, context _: Context) {
        controller.action = action
    }

    final class ReportController: UIViewController {
        var action: @MainActor () -> Void

        init(action: @escaping @MainActor () -> Void) {
            self.action = action

            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("Built in code only.")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            action()
        }
    }
}
