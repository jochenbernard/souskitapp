@testable import DesignSystem
import Testing
import UIKit

@MainActor
@Suite("Share sheet anchor")
struct ShareSheetAnchorTests {
    @Test("a bar button a window shows takes the popover")
    func shownBarButton() {
        let barButtonItem = UIBarButtonItem(title: "Share")
        let screenController = UIViewController()
        screenController.navigationItem.rightBarButtonItem = barButtonItem
        let window = UIWindow(frame: CGRect(x: 0.0, y: 0.0, width: 834.0, height: 1_210.0))
        window.rootViewController = UINavigationController(rootViewController: screenController)
        window.isHidden = false
        window.layoutIfNeeded()

        let sourceItem = SousShareSheet.sourceItem(barButtonItem: barButtonItem, view: screenController.view)

        #expect(sourceItem as? UIBarButtonItem === barButtonItem)
    }

    @Test("a bar button no bar shows leaves the popover on the view")
    func barButtonOutsideABar() {
        let view = UIView()
        let window = UIWindow(frame: CGRect(x: 0.0, y: 0.0, width: 834.0, height: 1_210.0))
        window.addSubview(view)

        let sourceItem = SousShareSheet.sourceItem(barButtonItem: UIBarButtonItem(title: "Share"), view: view)

        #expect(sourceItem as? UIView === view)
    }

    @Test("a view outside a window leaves the popover nothing to point at")
    func viewOutsideAWindow() {
        let sourceItem = SousShareSheet.sourceItem(barButtonItem: UIBarButtonItem(title: "Share"), view: UIView())

        #expect(sourceItem == nil)
    }
}
