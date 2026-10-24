import DesignSystem
import SwiftUI

private struct CardMenuModifier<Preview: View>: ViewModifier {
    @LineContainerRadius private var radius

    let items: [CardMenuItem]
    let open: @MainActor () -> Void
    let preview: @MainActor () -> Preview

    func body(content: Content) -> some View {
        content
            .background {
                CardMenuAnchor(menu: menu)
            }
            // VoiceOver lists no context menu, so its choices beyond opening are the card's actions too.
            .accessibilityActions {
                ForEach(items, id: \.title) { item in
                    Button(item.title, action: item.action)
                }
            }
    }

    private var menu: CardMenu {
        let makePreview = preview

        return CardMenu(
            items: items,
            open: open,
            preview: { AnyView(makePreview()) },
            cornerRadius: radius
        )
    }
}

extension View {
    /// Gives this card a context menu, which a long press opens with a preview of what the card opens, and in which a
    /// tap on the preview opens it.
    ///
    /// The card is to lie in a scroll view, which opens the menu.
    ///
    /// - Parameters:
    ///   - items: The menu's choices after Open.
    ///   - open: Opens what the card opens.
    ///   - preview: What the card opens, at a glance, made as the menu opens.
    /// - Returns: The card, with its menu.
    func cardMenu(
        items: [CardMenuItem],
        open: @escaping @MainActor () -> Void,
        preview: @escaping @MainActor () -> some View
    ) -> some View {
        modifier(
            CardMenuModifier(
                items: items,
                open: open,
                preview: preview
            )
        )
    }
}

#Preview("Card with a menu") {
    ScrollView {
        Text(verbatim: "Brioche")
            .sousRow()
            .cardMenu(
                items: [
                    CardMenuItem(
                        title: "Start cooking",
                        systemImage: "frying.pan",
                        action: {}
                    )
                ],
                open: {},
                preview: { Text(verbatim: "Brioche").padding(SousSpacing.large) }
            )
            .sousPagePadding()
    }
    .sousPage()
}
