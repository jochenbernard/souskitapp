import SwiftUI

private struct SousCalloutModifier: ViewModifier {
    @LineContainerRadius private var radius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)

        return content
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
    /// Sets this view apart as a callout, for what a screen needs the reader to notice.
    ///
    /// - Returns: The view, in a callout.
    public func sousCallout() -> some View {
        modifier(SousCalloutModifier())
    }
}

#Preview("Callout") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text(verbatim: "The folder no longer exists.")
            .sousCallout()

        Text(verbatim: "This recipe could not be read, and neither could the folder holding it.")
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
