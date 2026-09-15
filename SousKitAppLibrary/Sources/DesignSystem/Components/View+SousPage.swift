import SwiftUI

extension View {
    /// Draws this screen on `groupedBackground`, the ground of a `List`.
    ///
    /// - Returns: The screen, on the page ground.
    public func sousPage() -> some View {
        background(.groupedBackground)
    }

    /// Pads this view to the page's edges: ``SousSpacing/large`` across and ``SousSpacing/small``
    /// down.
    ///
    /// It goes on a screen's content rather than on the screen, so a scroll view scrolls the
    /// padding with the content, and on anything else at the page's edge, a bottom bar included.
    ///
    /// - Returns: The view, padded to the page's edges.
    public func sousPagePadding() -> some View {
        padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.small)
    }
}

#Preview("Page") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Boeuf Bourguignon")
            .font(.title3)

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .font(.body)

        Text(verbatim: "1.2 kg \u{B7} 150C \u{B7} 3 h \u{B7} serves 6")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
