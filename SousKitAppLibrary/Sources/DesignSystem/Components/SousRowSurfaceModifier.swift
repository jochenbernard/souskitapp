import SwiftUI

private struct SousRowSurfaceModifier: ViewModifier {
    @LineContainerRadius private var radius

    func body(content: Content) -> some View {
        content
            .sousSurface(RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    /// Draws a row's surface behind this view, with the corner radius every box takes, for a row that already takes
    /// ``sousRowPadding()`` or a card padded its own way.
    ///
    /// - Returns: The view, on a row's surface.
    public func sousRowSurface() -> some View {
        modifier(SousRowSurfaceModifier())
    }
}

#Preview("Row surface") {
    VStack(alignment: .leading, spacing: SousSpacing.small) {
        Text(verbatim: "Boeuf Bourguignon")
            .font(.title3)

        Text(verbatim: "Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(SousSpacing.large)
    .sousRowSurface()
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
