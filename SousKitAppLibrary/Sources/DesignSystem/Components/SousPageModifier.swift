import SwiftUI

/// Draws the ground a screen sits on, and sets the text token on what the screen holds.
private struct SousPageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(SousColor.text)
            .background(SousColor.background)
    }
}

extension View {
    /// Draws this screen on the page ground, with what it holds set in ``SousColor/text``.
    ///
    /// Text that steps away from that token, a caption in ``SousColor/textMuted`` or a symbol
    /// drawn quieter, sets its own foreground style and still wins.
    ///
    /// - Returns: The screen, on the page ground.
    public func sousPage() -> some View {
        modifier(SousPageModifier())
    }
}

#Preview("Page") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Boeuf Bourguignon")
            .sousTextStyle(.heading)

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousTextStyle(.body)

        Text(verbatim: "1.2 kg \u{B7} 150C \u{B7} 3 h \u{B7} serves 6")
            .sousTextStyle(.data)
            .foregroundStyle(SousColor.textMuted)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .sousPage()
}
