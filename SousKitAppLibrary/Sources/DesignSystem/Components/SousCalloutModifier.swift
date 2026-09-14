import SwiftUI

/// Draws the wash and the outline under a callout.
private struct SousCalloutModifier: ViewModifier {
    /// The height of one `.body` line, before Dynamic Type scales it.
    @ScaledMetric(relativeTo: .body) private var scaledBodyLineHeight = 20.3

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

    /// Half the height of a callout of one line, which is the radius a capsule takes there.
    private var radius: CGFloat {
        (scaledBodyLineHeight + SousSpacing.medium * 2.0) / 2.0
    }
}

extension View {
    /// Draws this view in a callout, across the full width of what holds it.
    ///
    /// The wash is `quaternaryAccentFill`, inside an outline in `accent`. Text in it is set in
    /// `accent`, which a foreground style closer to the text still overrides.
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
    .font(.body)
    .padding(.horizontal, SousSpacing.large)
    .padding(.vertical, SousSpacing.small)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(.groupedBackground)
}
