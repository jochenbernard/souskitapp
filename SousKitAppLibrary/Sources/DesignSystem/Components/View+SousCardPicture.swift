import SwiftUI

private struct SousCardPictureModifier: ViewModifier {
    @LineContainerRadius private var radius

    let endsCard: Bool

    func body(content: Content) -> some View {
        content
            // On the card's own ground, which hides the border drawn behind it, so the border over it is drawn once.
            .background(.secondaryGroupedBackground)
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: radius,
                    bottomLeadingRadius: endsCard ? radius : 0.0,
                    bottomTrailingRadius: endsCard ? radius : 0.0,
                    topTrailingRadius: radius
                )
                .sousBorder()
            }
    }
}

extension View {
    /// Sets this picture at the top of a card on ``sousRowSurface()``, under the card's border, with a line along its
    /// bottom edge that divides it from the rest of the card.
    ///
    /// The card clips the picture to its corners.
    ///
    /// - Parameter endsCard: Whether the card ends with the picture, which then takes the card's border along its
    ///   bottom instead of the line.
    /// - Returns: The picture, under the card's border.
    public func sousCardPicture(endsCard: Bool = false) -> some View {
        modifier(SousCardPictureModifier(endsCard: endsCard))
    }
}

#Preview("Card picture") {
    @Previewable @LineContainerRadius var radius

    VStack(alignment: .leading, spacing: 0.0) {
        SousPlaceholder(symbol: "birthday.cake", color: .orange)
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .sousCardPicture()

        Text(verbatim: "Madeleines")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.medium)
    }
    .frame(width: 200.0)
    .sousRowSurface()
    .clipShape(.rect(cornerRadius: radius))
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
