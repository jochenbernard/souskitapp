import SwiftUI

private struct SousRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .sousRowPadding()
            .sousRowSurface()
    }
}

extension View {
    /// Draws this view as a row.
    ///
    /// - Returns: The view, as a row.
    public func sousRow() -> some View {
        modifier(SousRowModifier())
    }
}

#Preview("Row") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text(verbatim: "Boeuf Bourguignon")
            .sousRow()

        Text(verbatim: "Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousRow()
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
