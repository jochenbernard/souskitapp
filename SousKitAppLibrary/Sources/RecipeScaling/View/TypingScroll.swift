import DesignSystem
import SwiftUI

private struct TypingScroll: ViewModifier {
    let keyPresses: Int

    @Namespace private var scrollTarget

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .id(scrollTarget)
                .onChange(of: keyPresses) {
                    withAnimation(.spring(duration: 0.35, bounce: 0.0)) {
                        proxy.scrollTo(scrollTarget)
                    }
                }
        }
    }
}

extension View {
    /// Scrolls this view back into view on each key press typed into it, so a cook sees what they type.
    ///
    /// - Parameter keyPresses: How many key presses the view has taken, counted up on each one.
    /// - Returns: The view, scrolled into view as it is typed into.
    func scrollsIntoView(onChangeOf keyPresses: Int) -> some View {
        modifier(TypingScroll(keyPresses: keyPresses))
    }
}

#Preview("Scrolled into view while typing") {
    @Previewable @State var text = "12"
    @Previewable @State var keyPresses = 0

    ScrollView {
        VStack(spacing: SousSpacing.xLarge) {
            TextField(text: $text, label: { Text(verbatim: "Servings") })
                .keyboardType(.decimalPad)
                .font(.largeTitle)
                .onChange(of: text) {
                    keyPresses += 1
                }
                .scrollsIntoView(onChangeOf: keyPresses)

            Rectangle()
                .fill(.tertiaryFill)
                .frame(height: 1_200.0)
        }
        .sousPagePadding()
    }
    .sousPage()
}
