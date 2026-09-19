import SwiftUI

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
