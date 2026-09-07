import SwiftUI

/// Draws the wash the brand gives a callout, which the seven semantic tokens do not name.
private struct SousCalloutModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(SousColor.accentText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
            .background {
                RoundedRectangle(cornerRadius: SousRadius.medium)
                    .fill(Color(light: SousPalette.scorch, dark: SousPalette.sear))
            }
    }
}

extension View {
    /// Draws this view in a callout, across the full width of what holds it.
    ///
    /// The wash is ``SousPalette/scorch`` on light and ``SousPalette/sear`` on dark, the pair the
    /// brand names for highlighted rows and callouts. Text in it is set in
    /// ``SousColor/accentText``, which a foreground style closer to the text still overrides.
    ///
    /// - Returns: The view, in a callout.
    public func sousCallout() -> some View {
        modifier(SousCalloutModifier())
    }
}

#Preview("Callout") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("This recipe could not be read")
            .sousTextStyle(.body)
            .sousCallout()

        Text("The folder no longer exists.")
            .sousTextStyle(.body)
            .sousCallout()
    }
    .padding(SousSpacing.xLarge)
    .background(SousColor.background)
}
