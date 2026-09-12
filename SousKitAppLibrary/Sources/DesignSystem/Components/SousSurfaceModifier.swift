import SwiftUI

/// Draws the fill and border a card, row, or sheet sits on.
private struct SousSurfaceModifier<Surface: InsettableShape>: ViewModifier {
    let shape: Surface

    func body(content: Content) -> some View {
        content.background {
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
    /// The shape names the role: a capsule for a row, ``SousRadius/large`` for a card or a sheet.
    /// Padding stays at the call site, since it varies with what is on the surface.
    ///
    /// - Parameter shape: The shape the surface takes.
    /// - Returns: The view, on a surface.
    public func sousSurface(_ shape: some InsettableShape) -> some View {
        modifier(SousSurfaceModifier(shape: shape))
    }
}

#Preview("Surface") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Boeuf Bourguignon")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.medium)
            .sousSurface(Capsule())

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.xLarge)
            .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    }
    .padding(SousSpacing.xLarge)
    .background(SousColor.background)
}
