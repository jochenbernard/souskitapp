import SwiftUI

/// Pads a row and draws its surface.
private struct SousRowModifier: ViewModifier {
    @LineContainerRadius private var radius

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.medium)
            .sousSurface(RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    /// Draws this view as a row, on a surface across the full width of what holds it.
    ///
    /// A row of one line is a capsule, and keeps that curve where its text wraps.
    ///
    /// - Returns: The view, as a row.
    public func sousRow() -> some View {
        modifier(SousRowModifier())
    }
}

#Preview("Row") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Boeuf Bourguignon")
            .sousRow()

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousRow()
    }
    .font(.body)
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
