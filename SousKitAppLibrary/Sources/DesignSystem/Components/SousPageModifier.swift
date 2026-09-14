import SwiftUI

/// Draws the ground a screen sits on.
private struct SousPageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.groupedBackground)
    }
}

extension View {
    /// Draws this screen on `groupedBackground`, the ground of a `List`.
    ///
    /// - Returns: The screen, on the page ground.
    public func sousPage() -> some View {
        modifier(SousPageModifier())
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
    .padding(.horizontal, SousSpacing.large)
    .padding(.vertical, SousSpacing.small)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
