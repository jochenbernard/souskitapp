import SwiftUI

/// Draws the wash and the outline under a callout.
private struct SousCalloutModifier: ViewModifier {
    @LineContainerRadius private var radius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)

        return content
            .font(.body)
            .foregroundStyle(.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.medium)
            .background {
                shape
                    .fill(.quaternaryAccentFill)
            }
            .overlay {
                shape.strokeBorder(.accent, lineWidth: 1.0)
            }
    }
}

extension View {
    /// Draws this view in a callout, across the full width of what holds it.
    ///
    /// The wash is `quaternaryAccentFill`, inside an outline in `accent`. Text in it is set in
    /// `.body` and `accent`, which a font or foreground style closer to the text still overrides.
    ///
    /// - Returns: The view, in a callout.
    public func sousCallout() -> some View {
        modifier(SousCalloutModifier())
    }
}

#Preview("Callout") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("The folder no longer exists.")
            .sousCallout()

        Text("This recipe could not be read, and neither could the folder holding it.")
            .sousCallout()
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
