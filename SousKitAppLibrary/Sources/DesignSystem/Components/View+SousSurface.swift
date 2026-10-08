import SwiftUI

extension View {
    /// Draws this view on a surface, such as a card or a sheet.
    ///
    /// A row takes ``sousRow()`` instead, and a card ``sousRowSurface()``, for the radius every box
    /// shares. Padding stays at the call site, since it varies with what is on the surface.
    ///
    /// - Parameter shape: The shape the surface takes.
    /// - Returns: The view, on a surface.
    public func sousSurface(_ shape: some InsettableShape) -> some View {
        background {
            shape
                .fill(.secondaryGroupedBackground)
                .shadow(
                    color: .separator.opacity(0.25),
                    radius: 12.0
                )
                .overlay {
                    shape.sousBorder()
                }
        }
    }
}

#Preview("Surface") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text(verbatim: "Boeuf Bourguignon")
            .sousRow()

        Text(verbatim: "Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.xLarge)
            .sousRowSurface()
    }
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
