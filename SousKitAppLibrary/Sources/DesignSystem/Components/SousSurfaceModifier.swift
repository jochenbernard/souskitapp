import SwiftUI

/// Draws the fill and border a card, row, or sheet sits on.
private struct SousSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        return content.background {
            shape
                .fill(SousColor.surface)
                .overlay {
                    shape.strokeBorder(SousColor.border, lineWidth: 1.0)
                }
        }
    }
}

extension View {
    /// Draws this view on a surface: the ``SousColor/surface`` fill inside a ``SousColor/border``.
    ///
    /// The radius names the role: ``SousRadius/medium`` for a row, ``SousRadius/large`` for a card
    /// or a sheet. Padding stays at the call site, since it varies with what is on the surface.
    ///
    /// - Parameter cornerRadius: The radius the surface is rounded to.
    /// - Returns: The view, on a surface.
    public func sousSurface(cornerRadius: CGFloat) -> some View {
        modifier(SousSurfaceModifier(cornerRadius: cornerRadius))
    }
}

#Preview("Surface") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Boeuf Bourguignon")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
            .sousSurface(cornerRadius: SousRadius.medium)

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.xLarge)
            .sousSurface(cornerRadius: SousRadius.large)
    }
    .padding(SousSpacing.xLarge)
    .background(SousColor.background)
}
