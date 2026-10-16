import SwiftUI

private struct SousTypingScrollModifier: ViewModifier {
    let text: String

    // Whether the keyboard types into a field in the view.
    @FocusState private var isTyping: Bool

    @Namespace private var scrollTarget

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .focused($isTyping)
                .id(scrollTarget)
                .onChange(of: text) {
                    guard isTyping else {
                        return
                    }

                    withAnimation(.spring(duration: 0.35, bounce: 0.0)) {
                        proxy.scrollTo(scrollTarget)
                    }
                }
        }
    }
}

extension View {
    /// Scrolls this view back into view when what it holds changes while the keyboard types into it, so a cook sees
    /// what they type.
    ///
    /// - Parameter text: What the view holds.
    /// - Returns: The view, scrolled into view as it is typed into.
    func sousScrollsIntoViewWhileTyping(_ text: String) -> some View {
        modifier(SousTypingScrollModifier(text: text))
    }
}

#Preview("Scrolled into view while typing") {
    @Previewable @State var text = "12"

    ScrollView {
        VStack(spacing: SousSpacing.xLarge) {
            TextField(
                text: $text,
                label: { Text(verbatim: "Servings") }
            )
            .keyboardType(.decimalPad)
            .font(.largeTitle)
            .sousScrollsIntoViewWhileTyping(text)

            Rectangle()
                .fill(.tertiaryFill)
                .frame(height: 1_200.0)
        }
        .sousPagePadding()
    }
    .sousPage()
}
