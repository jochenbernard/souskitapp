import SwiftUI

/// Lies behind a card and opens its menu on a long press, from UIKit, where a tap on the preview opens what the card
/// opens, which SwiftUI's `contextMenu(menuItems:preview:)` does not do.
///
/// The interaction sits on the scroll view the card lies in, one for all its cards, so each card keeps its own tap.
struct CardMenuAnchor: UIViewRepresentable {
    let menu: CardMenu

    func makeUIView(context _: Context) -> AnchorView {
        AnchorView(menu: menu)
    }

    func updateUIView(_ view: AnchorView, context _: Context) {
        view.menu = menu
    }

    /// The card's place on the screen, which the scroll view's menus find it by.
    final class AnchorView: UIView {
        let token = UUID()
        var menu: CardMenu

        private var menus: ScrollViewMenus?

        init(menu: CardMenu) {
            self.menu = menu

            super.init(frame: .zero)

            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("Built in code only.")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            menus?.remove(self)
            menus = nil

            guard window != nil, let scrollView = enclosingScrollView else {
                return
            }

            let scrollViewMenus = ScrollViewMenus.menus(of: scrollView)
            scrollViewMenus.add(self)
            menus = scrollViewMenus
        }

        /// The scroll view the card scrolls in.
        private var enclosingScrollView: UIScrollView? {
            sequence(first: superview, next: { $0?.superview })
                .lazy
                .compactMap({ $0 as? UIScrollView })
                .first
        }
    }

    /// The menus of the cards in one scroll view, which opens the one a long press lands on.
    ///
    /// The cards hold it, and it leaves the scroll view with the last of them.
    final class ScrollViewMenus: NSObject, UIContextMenuInteractionDelegate {
        private let anchors = NSHashTable<AnchorView>.weakObjects()
        private weak var scrollView: UIScrollView?
        private var interaction: UIContextMenuInteraction?

        private init(scrollView: UIScrollView) {
            self.scrollView = scrollView

            super.init()

            let menuInteraction = UIContextMenuInteraction(delegate: self)
            scrollView.addInteraction(menuInteraction)
            interaction = menuInteraction
        }

        /// The menus already on a scroll view, or new ones.
        static func menus(of scrollView: UIScrollView) -> ScrollViewMenus {
            let existing = scrollView.interactions
                .lazy
                .compactMap({ ($0 as? UIContextMenuInteraction)?.delegate as? ScrollViewMenus })
                .first

            return existing ?? ScrollViewMenus(scrollView: scrollView)
        }

        func add(_ anchor: AnchorView) {
            anchors.add(anchor)
        }

        func remove(_ anchor: AnchorView) {
            anchors.remove(anchor)

            if anchors.allObjects.isEmpty, let interaction {
                scrollView?.removeInteraction(interaction)
                self.interaction = nil
            }
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configurationForMenuAtLocation location: CGPoint
        ) -> UIContextMenuConfiguration? {
            guard
                let view = interaction.view,
                let anchor = anchors.allObjects.first(where: { $0.convert($0.bounds, to: view).contains(location) })
            else {
                return nil
            }

            let cardMenu = anchor.menu
            let window = view.window

            return UIContextMenuConfiguration(
                identifier: anchor.token.uuidString as any NSCopying,
                previewProvider: { Self.previewController(of: cardMenu, in: window) },
                actionProvider: { _ in Self.menuElement(of: cardMenu) }
            )
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configuration: UIContextMenuConfiguration,
            highlightPreviewForItemWithIdentifier _: any NSCopying
        ) -> UITargetedPreview? {
            targetedPreview(of: configuration, in: interaction)
        }

        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configuration: UIContextMenuConfiguration,
            dismissalPreviewForItemWithIdentifier _: any NSCopying
        ) -> UITargetedPreview? {
            targetedPreview(of: configuration, in: interaction)
        }

        func contextMenuInteraction(
            _: UIContextMenuInteraction,
            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
            animator: any UIContextMenuInteractionCommitAnimating
        ) {
            guard let anchor = anchor(of: configuration) else {
                return
            }

            let open = anchor.menu.open

            // The screen opens as the preview lifts away, rather than once it has settled back onto its card.
            animator.preferredCommitStyle = .pop
            animator.addAnimations(open)
        }

        private func anchor(of configuration: UIContextMenuConfiguration) -> AnchorView? {
            anchors.allObjects.first(where: { $0.token.uuidString == configuration.identifier as? String })
        }

        /// The card as it lies on the screen, which the menu lifts out of and settles back onto.
        private func targetedPreview(
            of configuration: UIContextMenuConfiguration,
            in interaction: UIContextMenuInteraction
        ) -> UITargetedPreview? {
            guard
                let anchor = anchor(of: configuration),
                let view = interaction.view
            else {
                return nil
            }

            let frame = anchor.convert(anchor.bounds, to: view)

            guard
                let snapshot = view.resizableSnapshotView(
                    from: frame,
                    afterScreenUpdates: false,
                    withCapInsets: .zero
                )
            else {
                return nil
            }

            let parameters = UIPreviewParameters()
            parameters.visiblePath = UIBezierPath(roundedRect: snapshot.bounds, cornerRadius: anchor.menu.cornerRadius)
            parameters.backgroundColor = .clear

            return UITargetedPreview(
                view: snapshot,
                parameters: parameters,
                target: UIPreviewTarget(container: view, center: CGPoint(x: frame.midX, y: frame.midY))
            )
        }

        private static func previewController(of menu: CardMenu, in window: UIWindow?) -> UIViewController {
            let controller = UIHostingController(rootView: menu.preview())
            controller.sizingOptions = .preferredContentSize
            controller.view.backgroundColor = .clear

            if let window {
                controller.preferredContentSize = controller.sizeThatFits(in: window.bounds.size)
            }

            return controller
        }

        private static func menuElement(of menu: CardMenu) -> UIMenu {
            let open = UIAction(
                title: String(localized: "Open", bundle: .module),
                image: UIImage(systemName: "arrow.up.forward.square"),
                handler: { _ in menu.open() }
            )
            let items = menu.items.map { item in
                UIAction(
                    title: item.title,
                    image: UIImage(systemName: item.systemImage),
                    handler: { _ in item.action() }
                )
            }

            return UIMenu(children: [open] + items)
        }
    }
}
