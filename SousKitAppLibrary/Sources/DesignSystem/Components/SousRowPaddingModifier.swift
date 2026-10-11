import SwiftUI

private struct SousRowPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.medium)
    }
}

extension View {
    /// Insets this view as a row's content, for a row whose surface is drawn apart from it, as a button's label is
    /// or a row in a ``SousRowGroup``.
    ///
    /// - Returns: The view, inset as a row.
    public func sousRowPadding() -> some View {
        modifier(SousRowPaddingModifier())
    }
}

#Preview("Row padding") {
    Button(
        action: {},
        label: {
            Text(verbatim: "Boeuf Bourguignon")
                .sousRowPadding()
                .contentShape(.rect)
        }
    )
    .buttonStyle(.plain)
    .sousRowSurface()
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
