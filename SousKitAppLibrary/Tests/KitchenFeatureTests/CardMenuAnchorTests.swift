@testable import KitchenFeature
import SwiftUI
import Testing
import UIKit

@Suite("Card menu anchors", .timeLimit(.minutes(1)))
struct CardMenuAnchorTests {
    @MainActor
    private func makeAnchor() -> CardMenuAnchor.AnchorView {
        CardMenuAnchor.AnchorView(
            menu: CardMenu(
                items: [],
                open: {},
                preview: { AnyView(EmptyView()) },
                cornerRadius: 0.0
            )
        )
    }

    @MainActor
    @Test("a card is under a press on it, and not once a lazy grid hides it for reuse")
    func hiddenCardIsNotShown() {
        let page = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 400.0, height: 800.0))
        let cell = UIView(frame: CGRect(x: 16.0, y: 200.0, width: 180.0, height: 200.0))
        let anchor = makeAnchor()
        let press = CGPoint(x: 100.0, y: 300.0)

        anchor.frame = cell.bounds
        cell.addSubview(anchor)
        page.addSubview(cell)

        #expect(anchor.isShown(at: press, in: page))
        #expect(!anchor.isShown(at: CGPoint(x: 300.0, y: 300.0), in: page))

        cell.isHidden = true

        #expect(!anchor.isShown(at: press, in: page))

        cell.isHidden = false
        cell.alpha = 0.0

        #expect(!anchor.isShown(at: press, in: page))
    }
}
